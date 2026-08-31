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
          serviceConfig = {
            # Block execution until the internet is actively reachable
            ExecStartPre = "${pkgs.networkmanager}/bin/nm-online -q --timeout=30";
            ExecStart = "${inputs.self}/home/shared/bin/bw_backup.sh";
            # do not start/restart the service when running 'nixos-rebuild switch'
            RemainAfterExit = true;
            RestartIfChanged = false;
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
