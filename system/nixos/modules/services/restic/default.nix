{
  config,
  hostname,
  lib,
  pkgs,
  secrets_path,
  username,
  ...
}:
with lib;
let
  home = "${config.users.users.${username}.home}";
  cfg = config.mettavi.system.services.restic;
in
{
  options.mettavi.system.services.restic = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure restic backup jobs";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # CHECK: not sure if this is required
      rclone # sync files and directories to and from major cloud storage
    ];

    services.restic = {
      backups =
        # set common options here
        let
          checkOpts = [
            "--with-cache" # just to make checks faster
          ];
          # generate and add a script to the system path, that has the same
          # environment variables set as the systemd service
          createWrapper = true;
          extraBackupArgs = [
            "--tag ${hostname}"
          ];
          # Prevent the system from sleeping while backing up
          inhibitsSleep = true;
          # create the repo if it doesn't exist
          initialize = true;
          # Patterns to exclude when backing up
          home_exclude = [
            "${home}/.local/share/Trash"
            "${home}/.cache"
            "${home}/Downloads"
            "${home}/.npm"
            "${home}/.local/share/containers"
            "!${home}/.local/share/containers/storage/volumes"
          ];
          nixos_exclude = [
            ".cache"
            ".log"
            ".tmp"
            ".Trash"
            "/var/lib/containers"
            "!/var/lib/containers/storage/volumes"
          ];
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 5"
            "--keep-monthly 12"
            "--keep-yearly 10"
            "--group-by tags"
          ];
          runCheck = true;
          # When to run the backup
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
        in
        {
          "oona-local" = {
            inherit
              extraBackupArgs
              home_exclude
              nixos_exclude
              inhibitsSleep
              initialize
              pruneOpts
              runCheck
              ;
            checkOpts = "${checkOpts}" ++ [
              "--read-data" # also check integrity of the actual data
            ];
            # Patterns to exclude when backing up
            exclude = nixos_exclude ++ home_exclude;
            passwordFile = config.sops.secrets."users/${username}/restic-oona-local".path;
            paths = [
              "/etc/group"
              "/etc/machine-id"
              "/etc/NetworkManager/system-connections"
              "/etc/passwd"
              "/etc/subgid"
              "${home}"
              "/root"
              "/var/backup"
              "/var/lib"
            ];
            repository = "/run/media/${username}/<disk_label>/${hostname}";
            # run backups when the removable disk is mounted, not on a schedule
            timerConfig = null;
            user = "root";
          };
          "oona-${username}-b2" = {
            inherit
              checkOpts
              createWrapper
              home_exclude
              inhibitsSleep
              initialize
              pruneOpts
              timerConfig
              ;
            exclude = home_exclude;
            extraBackupArgs = "${extraBackupArgs}" ++ [ "rclone.connections=100" ];
            passwordFile = config.sops.secrets."users/${username}/restic-oona-${username}-b2".path;
            paths = [
              "${home}"
            ];
            repository = "rclone:b2:oona-${username}";
            rcloneConfigFile = "${config.home-manager.users.${username}.sops.templates."rclone.conf".path}";
            rcloneOptions = { };
            # checks are resource-intensive in backblaze b2, so do not run a check every time
            runCheck = false;
            # need to test this (some files may be owned by root)
            user = "${username}";
          };
        };
    };
    sops.secrets = {
      # encryption password for local backup
      "users/${username}/restic-oona-local" = {
        sopsFile = "${secrets_path}/secrets/hosts/oona.yaml";
      };
      # encryption password for cloud backup to backblaze b2
      "users/${username}/restic-oona-${username}-b2" = {
        sopsFile = "${secrets_path}/secrets/hosts/oona.yaml";
      };
    };
    systemd.services.oona-local = {
      unitConfig = {
        Description = "Run a backup whenever the device is plugged in (and mounted)";
        # See https://bbs.archlinux.org/viewtopic.php?id=207050
        # RequiresMountsFor = "/run/media/xxx/Seagate Backup";
        # or use the ConditionPathIsMountPoint= option?
        # See https://unix.stackexchange.com/questions/281650/systemd-unit-requiresmountsfor-vs-conditionpathisdirectory
        # and https://www.mavjs.org/post/automatic-backup-restic-systemd-service/
        ConditionPathIsMountPoint = "/run/media/${username}/<disk_label>/oona-local";
        # or perhaps WantedBy= option?
      };
    };
  };
}
