{
  config,
  inputs,
  lib,
  pkgs,
  secrets_path,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.apps.bitwarden;
in
{
  options.mettavi.system.apps.bitwarden = {
    enable = lib.mkEnableOption "Install and configure bitwarden, along with a backup service";
    backup = mkOption {
      description = "Run a scheduled backup of the bitwarden database";
      type = types.bool;
      default = false;
    };
    server = {
      label = mkOption {
        description = "A label to identify the server used";
        type = types.str;
        default = "vaultwarden";
      };
      address = mkOption {
        description = "The address of the server used";
        type = types.str;
        default = "https://vault.${inputs.secrets.domain.primary}";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # to get authentication-related functionality, currently this cannot be installed by home-manager
      # see https://github.com/NixOS/nixpkgs/pull/339384#issuecomment-2372065297
      bitwarden-desktop
    ];

    # the backup option relies on an email module to enable email notification of failed backups
    mettavi.system.services.postfix.enable = mkIf cfg.backup true;

    systemd.user = mkIf cfg.backup {
      services = {
        # make an encrypted backup weekly
        "bitwarden-backup" = {
          enable = true;
          environment = {
            NODE_OPTIONS = "--dns-result-order=ipv4first";
            SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          };
          # Ensures the service starts after the network is available
          after = [ "network.target" ];
          description = "Backup the bitwarden database";
          # required by the script being scheduled
          path = with pkgs; [
            bash
            bitwarden-cli
            cacert # Explicitly ensure core CA certificates are visible in the path
            findutils
            coreutils
            openssl
            networkmanager # Keeps nm-online available for ExecStartPre
          ];
          restartIfChanged = false;
          # NB: NixOS prepends "set -e" to every 'script', so it is switched off explicitly below
          # and errors are handled by hand. Failures are reported by the OnFailure= unit.
          script = ''
            # Adapted from https://github.com/tmllull/BitwardenAutomatedBackup
            # and https://github.com/binarypatrick/BitwardenBackup
            # See https://github.com/dh024/Bitwarden_Export for a good INTERACTIVE export script

            # set the user account to backup
            USER="${username}"

            LABEL=${cfg.server.label}
            # create a two-letter abbreviation for the exported file
            LABEL_ABBREV="${substring 0 1 cfg.server.label + "w"}"

            # load env vars required by script and bw binary
            # shellcheck disable=SC1090,SC1091
            source "$XDG_CONFIG_HOME/sops-nix/secrets/users/$USER/$LABEL.env"

            # From here on: handle errors explicitly instead of aborting mid-way
            # (an aborted run used to leave bw logged in, which broke every later run)
            set +e
            set -uo pipefail
            umask 077

            # a missing or empty value fails the run immediately 
            # instead of producing a backup encrypted with an empty passphrase
            : "''${OPENSSL_ENC_PASS:?OPENSSL_ENC_PASS is not set}"
            export OPENSSL_ENC_PASS

            TIMESTAMP=$(date "+%Y%m%d")
            EXPORT_PATH="$HOME/backups/$LABEL"
            # EXPORT_PLAIN_FILE=bw_$TIMESTAMP.json
            # EXPORT_ENCRYPTED_FILE=bw_enc_$TIMESTAMP.json
            EXPORT_OPENSSL_FILE="''${LABEL_ABBREV}_$TIMESTAMP.enc"
            # EXPORT_ORG_PLAIN_FILE=bw_org_$TIMESTAMP.json
            # EXPORT_ORG_ENCRYPTED_FILE=bw_org_enc_$TIMESTAMP.json
            EXPORT_ORG_OPENSSL_FILE="''${LABEL_ABBREV}_org_$TIMESTAMP.enc"
            SERVER=${cfg.server.address}

            MAX_RETRIES=5
            RETRY_DELAY=15
            UNLOCK_RETRIES=3

            # Always leave bw logged out and the session cleared, whatever happened
            cleanup() {
              bw logout >/dev/null 2>&1 || true
              unset BW_SESSION
            }
            trap cleanup EXIT

            # Encrypt an export to the given file; remove partial output on failure.
            # Usage: export_vault <outfile> [extra bw export args...]
            export_vault() {
              local out="$1"
              shift
              if ! bw --raw export "$@" --format json 2>/dev/null \
                | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -pass env:OPENSSL_ENC_PASS -out "$out"; then
                rm -f "$out"
                return 1
              fi
              # sanity check: the file must exist and be non-empty
              [ -s "$out" ] || { rm -f "$out"; return 1; }
            }

            mkdir -p "$EXPORT_PATH"

            # Start from a clean state: a previous crashed run may have left a session behind,
            # and "bw config server" refuses to run while logged in
            bw logout >/dev/null 2>&1 || true

            if [ -n "$SERVER" ]; then
              if ! bw config server "$SERVER" >/dev/null; then
                echo "Error: could not set bw server to $SERVER" >&2
                exit 1
              fi
            fi

            echo "Attempting Bitwarden API login..."
            ATTEMPT=1
            LOGGED_IN=1
            while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
              if LOGIN_OUT=$(bw login --apikey 2>&1); then
                echo "Successfully authenticated with API key."
                LOGGED_IN=0
                break
              else
                echo "Login attempt $ATTEMPT failed: $LOGIN_OUT"
                echo "Network may be offline. Retrying in ''${RETRY_DELAY}s..."
                sleep "$RETRY_DELAY"
                ATTEMPT=$((ATTEMPT + 1))
              fi
            done

            if [ "$LOGGED_IN" -ne 0 ]; then
              echo "Error: Bitwarden API unreachable after $MAX_RETRIES attempts (API login failed)." >&2
              exit 1
            fi

            # Force a 5-second pause to let the Android Hotspot NAT clear its connection tracking table
            echo "Login successful. Cooling down for Hotspot routing..."
            sleep 5

            # Try to unlock the vault with internal fallback retries
            echo "Attempting vault unlock..."
            BW_SESSION=""
            UNLOCK_ATTEMPT=1
            while [ "$UNLOCK_ATTEMPT" -le "$UNLOCK_RETRIES" ]; do
              BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw 2>/dev/null)

              if [ -n "$BW_SESSION" ]; then
                echo "Vault unlocked successfully!"
                break
              else
                echo "Unlock attempt $UNLOCK_ATTEMPT stalled by hotspot NAT. Retrying in 10s..."
                sleep 10
                UNLOCK_ATTEMPT=$((UNLOCK_ATTEMPT + 1))
              fi
            done

            if [ -z "$BW_SESSION" ]; then
              echo "Error: vault unlock failed (master password decryption failed)." >&2
              exit 1
            fi
            # bw reads the session from the environment (keeps it out of the process list)
            export BW_SESSION

            echo "Exporting personal vault (encrypted with openssl)..."
            if ! export_vault "$EXPORT_PATH/$EXPORT_OPENSSL_FILE"; then
              echo "Error: personal vault export failed." >&2
              exit 1
            fi

            # ORGANIZATION
            if [ -n "''${BW_ORG_ID:-}" ]; then
              echo "Exporting organization vault (encrypted with openssl)..."
              if ! export_vault "$EXPORT_PATH/$EXPORT_ORG_OPENSSL_FILE" --organizationid "$BW_ORG_ID"; then
                echo "Error: organization vault export failed." >&2
                exit 1
              fi
            else
              echo "No organizational vault defined."
            fi

            # Cleanup old files (only reached if the exports above succeeded, so old
            # backups are never deleted without a fresh one in place).
            # NB: linux find does not allow "-mtime +12w", only "-mtime +n" where n is the no. of days
            NUM_FILES=$(find "$EXPORT_PATH" -type f | wc -l)
            if [ "$NUM_FILES" -gt 12 ]; then
              # keep backups from the last 12 weeks (7*12=84)
              find "$EXPORT_PATH" -type f -mtime +84 -delete
            fi

            echo "Export completed!"
          '';
          serviceConfig = {
            # Block execution until the internet is actively reachable
            ExecStartPre = "${pkgs.networkmanager}/bin/nm-online -q --timeout=30";
            Type = "oneshot";
            # No Restart= here: the script has its own retry loops, and restarting a oneshot
            # is what produced the "start-limit-hit" state
          };
          unitConfig = {
            # enable the service only for the main admin user
            ConditionUser = "${username}";
            # run the notifier if this unit fails for ANY reason (script error, ExecStartPre
            # timeout, missing env file, ...)
            OnFailure = "bitwarden-backup-notify.service";
          };
        };

        # sends a failure email, including the tail of the backup log
        "bitwarden-backup-notify" = {
          description = "Notify that the bitwarden backup failed";
          path = with pkgs; [
            coreutils
            hostname
            mailutils
            systemd
          ];
          serviceConfig.Type = "oneshot";
          script = ''
            {
              echo "bitwarden-backup.service failed on $(hostname) at $(date)."
              echo
              echo "Last log lines:"
              journalctl --user -u bitwarden-backup.service -n 30 --no-pager || true
            } | mail -s "${
              toUpper (substring 0 1 cfg.server.label) + (substring 1 (-1) cfg.server.label)
            } backup failed" ${inputs.secrets.email.personal}
          '';
        };
      };

      timers = {
        "bitwarden-backup" = {
          timerConfig = {
            OnCalendar = [ "Mon *-*-* 00:00:00" ]; # will use the globally configured timezone config
            # execute immediately it resumes if the last time was missed
            Persistent = true;
            Unit = "bitwarden-backup.service";
          };
          wantedBy = [ "timers.target" ];
        };
      };
    };

    home-manager.users.${username} =
      { config, nixosConfig, ... }:
      {
        # install the package used for making bitwarden backups
        home.packages = with pkgs; mkIf nixosConfig.mettavi.system.apps.bitwarden.backup [ bitwarden-cli ];

        # install the firefox extension
        programs.firefox.profiles."mettavi".extensions.packages =
          with pkgs.nur.repos.rycee.firefox-addons;
          optionals (config.mettavi.apps.firefox.enable) [ bitwarden ];

        sops.secrets = {
          # bitwarden .env file for use with cli
          "users/${username}/bitwarden.env" = {
            sopsFile = "${secrets_path}/secrets/apps/bitwarden.yaml";
          };
          "users/${username}/vaultwarden.env" = {
            sopsFile = "${secrets_path}/secrets/apps/vaultwarden.yaml";
          };
        };
        # setting autostart using the desktop GUI hardcodes the app path
        # in $XDG_CONFIG_HOME/autostart, causing failure
        # see https://discourse.nixos.org/t/bitwarden-unlock-with-system-authentication-on-nixos/68643/11
        xdg.autostart = {
          enable = true;
          entries = [
            "${pkgs.bitwarden-desktop}/share/applications/bitwarden.desktop"
          ];
        };
      };
  };
}
