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
  withRestic = (
    builtins.any (config: config.nyx.modules.shell.restic.enable) (
      builtins.attrValues config.home-manager.users
    )
  );
in
{
  launchd.daemons = mkIf (pkgs.stdenv.isDarwin && withRestic) {
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
  home-manager.sharedModules = [
    (
      { config, ... }:
      {
        options.nyx.modules.shell.restic = {
          enable = mkEnableOption "Install and configure the restic backup tool";
          useRestProf = mkOption {
            type = types.bool;
            default = true;
            description = "Use resticprofile to manage restic using config files";
          };
        };
        config =
          mkIf config.nyx.modules.shell.restic.enable {
            home.packages = with pkgs; [
              restic # Backup with delta transfers (eg. to cloud storage via rclone)
            ];
          }
          // mkIf config.nyx.modules.shell.restic.useRestProf {
            home.packages = with pkgs; [ resticprofile ]; # Configuration manager for restic
            xdg.configFile = {
              "resticprofile".source = ../../../../../home/shared/dots/resticprofile;
            };
          };
      }
    )
  ];
}
