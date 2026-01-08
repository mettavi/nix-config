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
  cfg = config.mettavi.apps.bitwarden;
in
{
  options.mettavi.apps.bitwarden = {
    enable = lib.mkEnableOption "Install and configure bitwarden, along with a backup service";
    backup = {
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
    ];

    systemd.user = mkIf cfg.backup {
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
            "multi-user.target"
            "timers.target"
          ];
        };
      };
    };
  };

  # home.sessionVariables = {
  #   # prevent nh from checking for flakes "experimental features" (which it can't read from determinate nix.conf)
  #   NH_NO_CHECKS = "1";
  # };
}
