{
  config,
  inputs,
  lib,
  pkgs,
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

    systemd.user = mkIf cfg.backup {
      # install the package used for making bitwarden backups
      services = {
        # make an encrypted backup weekly
        "bitwarden-backup" = {
          enable = true;
          # Ensures the service starts after the network is available
          after = [ "network.target" ];
          description = "Backup the bitwarden database";
          serviceConfig = {
            ExecStart = "${inputs.self}/home/shared/bin/bw_backup.sh";
            # do not start the service when running 'nixos-rebuild switch'
            RemainAfterExit = true;
            Restart = "on-failure";
            Type = "oneshot";
          };
          unitConfig = {
            # enable the service only for the main admin user
            ConditionUser = "${username}";
          };
        };
      };
      timers = {
        "bitwarden-backup" = {
          timerConfig = {
            OnCalendar = [ "Mon *-*-* 00:00:00 Australia/Melbourne" ];
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
      };
  };
}
