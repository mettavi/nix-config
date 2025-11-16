# This is a combined restic module for home-manager and darwin
{
  config,
  hostname,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.home-manager.users.${username}.mettavi.shell.restic;
in
{
  home-manager.users.${username} =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    with lib;
    let
      cfg = config.mettavi.shell.restic;
    in
    {
      options.mettavi.shell.restic = {
        # default is false, must be explicitly turned on for each user
        enable = mkEnableOption "Install and configure the restic backup tool";
        # IF using restic, default to managing it with resticprofile
        useRestProf = mkOption {
          type = types.bool;
          default = true;
          description = "Use resticprofile to manage restic using config files";
        };
      };
      config =
        mkIf cfg.enable {
          home.packages = with pkgs; [
            restic # Backup with delta transfers (eg. to cloud storage via rclone)
          ];
        }
        // mkIf cfg.useRestProf {
          home.packages = with pkgs; [ resticprofile ]; # Configuration manager for restic
          xdg.configFile = {
            "resticprofile".source = ../../../../home/shared/dots/resticprofile;
          };
        };
    };

  launchd.daemons = mkIf (pkgs.stdenv.isDarwin && cfg.enable) {
    resticprofile-backup = {
      serviceConfig = {
        EnvironmentVariables = {
          PATH = "/usr/local/sbin:/usr/local/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/${username}/.local/bin";
          RESTICPROFILE_SCHEDULE_ID = "${
            config.users.users.${username}.home
          }/.config/resticprofile/profiles.toml:backup@default";
        };
        Label = "${hostname}.resticprofile.${username}.default.backup";
        LimitLoadToSessionType = "System";
        LowPriorityBackgroundIO = false;
        LowPriorityIO = false;
        Nice = 0;
        ProcessType = "Standard";
        Program = "/etc/profiles/per-user/${username}/bin/resticprofile";
        ProgramArguments = [
          "/etc/profiles/per-user/${username}/bin/resticprofile"
          "--no-prio"
          "--no-ansi"
          "--config"
          "${config.users.users.${username}.home}/.config/resticprofile/profiles.toml"
          "run-schedule"
          "backup@default"
        ];
        StartCalendarInterval = [
          {
            Hour = 0;
            Minute = 30;
          }
        ];
        WorkingDirectory = "${config.users.users.${username}.home}/.nix-config";
      };
    };
    resticprofile-forget = {
      serviceConfig = {
        EnvironmentVariables = {
          PATH = "/usr/local/sbin:/usr/local/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/${username}/.local/bin";
          RESTICPROFILE_SCHEDULE_ID = "${
            config.users.users.${username}.home
          }/.config/resticprofile/profiles.toml:forget@default";
        };
        Label = "${hostname}.resticprofile.${username}.default.forget";
        LimitLoadToSessionType = "System";
        LowPriorityBackgroundIO = false;
        LowPriorityIO = false;
        Nice = 0;
        ProcessType = "Standard";
        Program = "/etc/profiles/per-user/${username}/bin/resticprofile";
        ProgramArguments = [
          "/etc/profiles/per-user/${username}/bin/resticprofile"
          "--no-prio"
          "--no-ansi"
          "--config"
          "${config.users.users.${username}.home}/.config/resticprofile/profiles.toml"
          "run-schedule"
          "forget@default"
        ];
        StartCalendarInterval = [
          {
            Hour = 1;
            Minute = 30;
            Weekday = 1;
          }
        ];
        WorkingDirectory = "${config.users.users.${username}.home}/.nix-config";
      };
    };
    resticprofile-check = {
      serviceConfig = {
        EnvironmentVariables = {
          PATH = "/usr/local/sbin:/usr/local/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/${username}/.local/bin";
          RESTICPROFILE_SCHEDULE_ID = "${
            config.users.users.${username}.home
          }/.config/resticprofile/profiles.toml:check@default";
        };
        Label = "${hostname}.resticprofile.${username}.default.check";
        LimitLoadToSessionType = "System";
        LowPriorityBackgroundIO = false;
        LowPriorityIO = false;
        Nice = 0;
        ProcessType = "Standard";
        Program = "/etc/profiles/per-user/${username}/bin/resticprofile";
        ProgramArguments = [
          "/etc/profiles/per-user/${username}/bin/resticprofile"
          "--no-prio"
          "--no-ansi"
          "--config"
          "${config.users.users.${username}.home}/.config/resticprofile/profiles.toml"
          "run-schedule"
          "check@default"
        ];
        StartCalendarInterval = [
          {
            Day = 1;
            Hour = 2;
            Minute = 0;
          }
        ];
        WorkingDirectory = "${config.users.users.${username}.home}/.nix-config";
      };
    };
  };
}
