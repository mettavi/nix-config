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
  cfg = config.mettavi.system.services.restic;
  home = "${config.users.users.${username}.home}";
  logfile_dir = "$XDG_STATE_HOME/logs/rclone";
  logfile = "${logfile_dir}/restic-${hostname}.log";
  # create an rclone shell script
  restic-rcl-b2 =
    pkgs.writeShellScriptBin "restic-rcl-b2.sh" # bash
      ''
        # create the base directory if it doesn't exist
        if [ ! -d ${logfile_dir} ]; then
          mkdir -p ${logfile_dir} 
        fi

        # copy the local restic backup to the cloud (backblaze b2)
        rclone --log-level INFO --log-file=${logfile} \
          --verbose --b2-hard-delete --checkers 100 --transfers 100 --stats 2m --order-by size,mixed,75 --max-backlog 10000 --progress --retries 1 --fast-list \
          sync ${
            config.services.restic.backups."${hostname}-local-home".repository
          } b2:${hostname}-${username}/
      '';
  vol_label = "${config.mettavi.system.services.restic.vol_label}";
in
{
  options.mettavi.system.services.restic = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure restic backup jobs";
    };
    vol_label = mkOption {
      type = types.str;
      default = "";
      description = "The volume label of the backup device (eg. 'luks-samt7')";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # CHECK: not sure if this is required
      rclone # sync files and directories to and from major cloud storage
      restic-rcl-b2
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
          # local backup of system
          "${hostname}-local-sys" = {
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
            exclude = nixos_exclude;
            passwordFile = config.sops.secrets."users/${username}/restic-${hostname}-local-sys".path;
            paths = [
              "/etc/group"
              "/etc/machine-id"
              "/etc/NetworkManager/system-connections"
              "/etc/passwd"
              "/etc/subgid"
              "/root"
              "/var/backup"
              "/var/lib"
            ];
            repository = "/run/media/${username}/${vol_label}/${hostname}/root";
            # run backups when the removable disk is mounted, not on a schedule
            timerConfig = null;
            user = "root";
          };
          # local backup of home directory
          "${hostname}-local-home" = {
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
            exclude = home_exclude;
            passwordFile = config.sops.secrets."users/${username}/restic-${hostname}-local-home".path;
            paths = [
              "${home}"
            ]
            ++ optionalString config.mettavi.system.services.paperless-ngx.enable [
              "${config.services.paperless.dataDir}/export"
            ];
            repository = "/run/media/${username}/${vol_label}/${hostname}/user";
            # run backups when the removable disk is mounted, not on a schedule
            timerConfig = null;
            user = "${username}";
          };
          # do a restic backup directly to cloud using rclone
          "${hostname}-${username}-b2" = {
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
            passwordFile = config.sops.secrets."users/${username}/restic-${hostname}-${username}-b2".path;
            paths = [
              "${home}"
            ]
            ++ optionalString config.mettavi.system.services.paperless-ngx.enable [
              "${config.services.paperless.dataDir}/export"
            ];

            repository = "rclone:b2:${hostname}-${username}";
            rcloneConfigFile = "${config.home-manager.users.${username}.sops.templates."rclone.conf".path}";
            rcloneOptions = {
              checkers = 100;
              fast-list = true;
              # restic already keeps deleted files
              b2-hard-delete = true;
              log-file = "${logfile}";
              max-backlog = 10000;
              order-by = "size,mixed,75";
              stats = "2m";
              transfers = 100;
              verbose = true;
            };
            # checks are resource-intensive in backblaze b2, so do not run a check every time
            runCheck = false;
            # need to test this (some files may be owned by root)
            user = "${username}";
          };
        };
    };
    sops.secrets = {
      # encryption password for local backup
      "users/${username}/restic-${hostname}-local" = {
        sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      };
      # encryption password for cloud backup to backblaze b2
      "users/${username}/restic-${hostname}-${username}-b2" = {
        sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      };
    };
    systemd.services = {
      "${hostname}-local-sys" = {
        unitConfig = {
          Description = "Run a backup whenever the device is plugged in (and mounted)";
          # See https://bbs.archlinux.org/viewtopic.php?id=207050
          # RequiresMountsFor = "/run/media/xxx/Seagate Backup";
          # or use the ConditionPathIsMountPoint= option?
          # See https://unix.stackexchange.com/questions/281650/systemd-unit-requiresmountsfor-vs-conditionpathisdirectory
          # and https://www.mavjs.org/post/automatic-backup-restic-systemd-service/
          ConditionPathIsMountPoint = "/run/media/${username}/${vol_label}/${hostname}/root";
          # or perhaps WantedBy= option?
        };
      };
      "${hostname}-local-home" = {
        unitConfig = {
          Description = "Run a backup whenever the device is plugged in (and mounted)";
          # See https://bbs.archlinux.org/viewtopic.php?id=207050
          # RequiresMountsFor = "/run/media/xxx/Seagate Backup";
          # or use the ConditionPathIsMountPoint= option?
          # See https://unix.stackexchange.com/questions/281650/systemd-unit-requiresmountsfor-vs-conditionpathisdirectory
          # and https://www.mavjs.org/post/automatic-backup-restic-systemd-service/
          ConditionPathIsMountPoint = "/run/media/${username}/${vol_label}/${hostname}/user";
          # or perhaps WantedBy= option?
        };
      };
    };
  };
}
