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
      # Cryptographic library that implements the SSL and TLS protocols (required for the bash script)
      openssl_3
    ];

    # the backup option relies on an email module to enable email notification of failed backups
    mettavi.system.services.postfix.enable = mkIf cfg.backup true;

    systemd.user = mkIf cfg.backup {
      # create the service used for making bitwarden backups
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
            mailutils
            openssl
            networkmanager # Keeps nm-online available for ExecStartPre
          ];
          restartIfChanged = false;
          script = ''
            #!/usr/bin/env bash

            # Adapted from https://github.com/tmllull/BitwardenAutomatedBackup
            # and https://github.com/binarypatrick/BitwardenBackup
            # See https://github.com/dh024/Bitwarden_Export for a good INTERACTIVE export script

            # set the user account to backup
            USER="${username}"

            LABEL=${cfg.server.label}
            LABEL_ABBREV="${substring 0 1 cfg.server.label + "w"}"
            # Capitalize the label for email
            LABEL_CAP="${toUpper (substring 0 1 cfg.server.label) + (substring 1 (-1) cfg.server.label)}"
            # load env vars required by script and bw binary
            # shellcheck disable=SC1090,SC1091
            source "$XDG_CONFIG_HOME/sops-nix/secrets/users/$USER/$LABEL.env"

            TIMESTAMP=$(date "+%Y%m%d")
            EXPORT_PATH="$HOME/backups/$LABEL"
            # EXPORT_PLAIN_FILE=bw_$TIMESTAMP.json
            # EXPORT_ENCRYPTED_FILE=bw_enc_$TIMESTAMP.json
            EXPORT_OPENSSL_FILE=''${LABEL_ABBREV}_$TIMESTAMP.enc
            # EXPORT_ORG_PLAIN_FILE=bw_org_$TIMESTAMP.json
            # EXPORT_ORG_ENCRYPTED_FILE=bw_org_enc_$TIMESTAMP.json
            EXPORT_ORG_OPENSSL_FILE=''${LABEL_ABBREV}_org_$TIMESTAMP.enc

            NOTIFICATION_EMAIL=${inputs.secrets.email.personal} # Email address used for notification if job fails
            NOTIFICATION_EMAIL_SUBJECT="$LABEL_CAP Unlock Failed"
            NOTIFICATION_EMAIL_BODY="The automated $LABEL_CAP backup failed when trying to unlock the vault"
            SERVER=${cfg.server.address}

            if [ ! -d "$EXPORT_PATH" ]; then
              echo "Folder '~/backups/$LABEL' does not exist. Creating it..."
              mkdir -p "$EXPORT_PATH"
            else
              echo "Folder '~/backups/$LABEL' already exists."
            fi

            MAX_RETRIES=5
            RETRY_DELAY=15
            ATTEMPT=1
            LOGGED_IN=1

            if [ -n "$SERVER" ]; then
              bw config server "$SERVER" 
            fi

            echo "Attempting Bitwarden API login..."
            while [ $ATTEMPT -le $MAX_RETRIES ]; do
              # Run login and capture errors silently
              if bw login --apikey >/dev/null 2>&1; then
                echo "Successfully authenticated with API key."
                LOGGED_IN=0
                break
              else
                echo "Login attempt $ATTEMPT failed. Network may be offline. Retrying in ''${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
                ATTEMPT=$((ATTEMPT + 1))
              fi
            done

            # If all retries failed, send ONE email and exit
            if [ $LOGGED_IN -ne 0 ]; then
              echo "Error: Bitwarden API unreachable after $MAX_RETRIES attempts."
              echo "$NOTIFICATION_EMAIL_BODY (API Login FetchError)" | mail -s "$NOTIFICATION_EMAIL_SUBJECT" "$NOTIFICATION_EMAIL"
              exit 1
            fi

            # Force a 5-second pause to let the Android Hotspot NAT clear its connection tracking table
            echo "Login successful. Cooling down for Hotspot routing..."
            sleep 5

            # Try to unlock the vault with internal fallback retries
            echo "Attempting vault unlock..."
            UNLOCK_ATTEMPT=1
            while [ $UNLOCK_ATTEMPT -le 3 ]; do
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
              echo "Error: Master password decryption failed."
              echo "$NOTIFICATION_EMAIL_BODY (Vault Unlock Failed)" | mail -s "$NOTIFICATION_EMAIL_SUBJECT" "$NOTIFICATION_EMAIL"
              bw logout
              exit 1
            fi

            # Unencrypted export (not recommended)
            #bw --raw --session $BW_SESSION export --format json --output $EXPORT_PATH/$EXPORT_PLAIN_FILE

            # Encrypted export using encrypted_json from bitwarden
            # echo "Export encrypted json using bitwarden format..."
            # bw --raw --session $BW_SESSION export --format encrypted_json --password $BW_PASSWORD --output $EXPORT_PATH/$EXPORT_ENCRYPTED_FILE
            # chmod 644 $EXPORT_PATH/$EXPORT_ENCRYPTED_FILE

            # Encrypted export using openssl
            echo "Export encrypted json using openssl..."
            (bw --raw --session "$BW_SESSION" export --format json 2>/dev/null) | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -k "$OPENSSL_ENC_PASS" -out "$EXPORT_PATH"/"$EXPORT_OPENSSL_FILE"

            # ORGANIZATION
            if [[ -n "$BW_ORG_ID" ]]; then
              # Unencrypted export (not recommended)
              #bw --raw --session $BW_SESSION export --organizationid $BW_ORG_ID --format json --output $EXPORT_PATH/$EXPORT_ORG_PLAIN_FILE

              # Encrypted export using encrypted_json from bitwarden
              # echo "Export encrypted json using bitwarden format..."
              # bw --raw --session $BW_SESSION export --organizationid $BW_ORG_ID --format encrypted_json --password $BW_PASSWORD --output $EXPORT_PATH/$EXPORT_ORG_ENCRYPTED_FILE
              # chmod 644 $EXPORT_PATH/$EXPORT_ORG_ENCRYPTED_FILE

              # Encrypted export using openssl
              echo "Export encrypted json using openssl..."
              bw --raw --session "$BW_SESSION" export --organizationid "$BW_ORG_ID" --format json | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -k "$OPENSSL_ENC_PASS" -out "$EXPORT_PATH"/"$EXPORT_ORG_OPENSSL_FILE"
            else
              echo
              echo "No organizational vault defined."
            fi

            # Cleanup old files.
            # Adjust the number of files to keep and days
            # depending on your use case.
            # NB: Once there are > 12 backups, "mtime +12w" will remove all backups older than 12 weeks
            NUM_FILES=$(find "$EXPORT_PATH" -type f | wc -l)
            if [ "$NUM_FILES" -gt 12 ]; then
              # keep backups from the last 12 weeks (7*12=84)
              # NB: linux find does not allow "-mtime +12w" etc, only "-mtime +n" where n is the no. of days
              find "$EXPORT_PATH" -type f -mtime +84 -exec rm {} \;
            fi

            echo "Export completed!"
            bw logout
          '';
          serviceConfig = {
            # Block execution until the internet is actively reachable
            ExecStartPre = "${pkgs.networkmanager}/bin/nm-online -q --timeout=30";
            # ExecStart = "${inputs.self}/home/shared/bin/bw_backup.sh";
            # do not start/restart the service when running 'nixos-rebuild switch'
            RemainAfterExit = true;
            Restart = "on-failure";
            # prevent being spammed with failure notifications when the bitwarden network is down
            # restart a maximum of 5 times within a 10-second interval
            Type = "oneshot";
            RestartSec = "30s"; # Wait 30 seconds before retrying
            # Force Node.js/Bitwarden CLI to prioritize stable IPv4 connections
          };
          unitConfig = {
            # enable the service only for the main admin user
            ConditionUser = "${username}";
            StartLimitIntervalSec = "300s"; # 5 minute window
            StartLimitBurst = 3; # Give up after 3 total tries
          };
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
          wantedBy = [
            "default.target"
            "timers.target"
          ];
        };
      };
    };
    home-manager.users.${username} =
      { nixosConfig, ... }:
      {
        # install the package used for making bitwarden backups
        home.packages = with pkgs; mkIf nixosConfig.mettavi.system.apps.bitwarden.backup [ bitwarden-cli ];

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
