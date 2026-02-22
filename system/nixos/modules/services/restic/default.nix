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
  resticSecrets = {
    sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
  };
  snapshots = "/mnt/snapshots";
  vol_label = "${config.mettavi.system.services.restic.vol_label}";
in
{
  options.mettavi.system.services.restic = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure restic backup jobs";
    };
    jobs = mkOption {
      type =
        with lib.types;
        attrsOf (
          submodule (
            { job, ... }:
            {
              options = {
                enable = mkOption {
                  type = bool;
                  default = true;
                  description = "Whether to enable this backup job";
                };
                label = mkOption {
                  type = str;
                  description = "The short name of the backup job";
                };
                exclusions = mkOption {
                  type = listOf str;
                  description = "A list of paths to exclude from the backup";
                };
                paths = mkOption {
                  type = listOf path;
                  description = "A list of paths to backup";
                };
                user = mkOption {
                  type = str;
                  description = "The user to run the backup job as";
                };
              };
            }
          )
        );
    };
    vol_label = mkOption {
      type = types.str;
      default = "";
      description = "The volume label of the backup device (eg. 'luks-samt7')";
    };
  };

  config = mkIf cfg.enable {
    # CONFIGURE RESTIC BACKUP JOBS USING MODULE OPTIONS
    mettavi.system.services.restic.jobs = {
      # BACKUP THE MAIN USER'S HOME DIRECTORY
      "${hostname}-local-home" =
        let
          user-snapshots = "${snapshots}/home";
        in
        {
          enable = true;
          label = "home";
          exclusions = [
            "${user-snapshots}/${username}/.local/share/Trash"
            "${user-snapshots}/${username}/.cache"
            "${user-snapshots}/${username}/Downloads"
            "${user-snapshots}/${username}/.npm"
            "${user-snapshots}/${username}/.local/share/containers"
            "!${user-snapshots}/${username}/.local/share/containers/storage/volumes"
          ];
          paths = [
            "${user-snapshots}/${username}"
          ];
          user = "${username}";
        };
      # BACKUP IMPORTANT SYSTEM DIRECTORIES
      "${hostname}-local-sys" =
        let
          sys-snapshots = "${snapshots}/sys";
        in
        {
          enable = true;
          label = "sys";
          exclusions = [
            "${sys-snapshots}/root/.cache"
            "${sys-snapshots}/.log"
            "${sys-snapshots}/.tmp"
            "${sys-snapshots}/.Trash"
            "${sys-snapshots}/var/lib/containers"
            "!${sys-snapshots}/var/lib/containers/storage/volumes"
          ];
          paths = [
            "${sys-snapshots}/etc/machine-id"
            "${sys-snapshots}/etc/NetworkManager/system-connections"
            "${sys-snapshots}/etc/passwd"
            "${sys-snapshots}/etc/subgid"
            "${sys-snapshots}/root"
            "${sys-snapshots}/var/backup"
            "${sys-snapshots}/var/lib"
          ]
          ++ optionalString config.mettavi.system.services.paperless-ngx.enable [
            "${sys-snapshots}/root/var/lib/paperless/export"
          ];
          user = "root";
        };
    };
    environment.systemPackages = with pkgs; [
      # CHECK: not sure if this is required
      rclone # sync files and directories to and from major cloud storage
      restic-rcl-b2
    ];

    services.restic = {
      backups = mapAttrs (
        job: jobsCfg:
        {
          backupPrepareCommand = ''
            btrfs subvolume snapshot -r /home ${snapshots}/home
            btrfs subvolume snapshot -r / ${snapshots}/sys
          '';
          backupCleanupCommand = ''
            btrfs subvolume delete ${snapshots}/home
            btrfs subvolume delete ${snapshots}/sys
          '';
          checkOpts = [
            "--with-cache" # just to make checks faster
            "--read-data" # also check integrity of the actual data
          ];
          createWrapper = true;
          # Patterns to exclude when backing up
          exclude = jobsCfg.exclusions;
          extraBackupArgs = [
            "--tag ${hostname}"
          ];
          # Prevent the system from sleeping while backing up
          inhibitsSleep = true;
          # create the repo if it doesn't exist
          initialize = true;
          passwordFile =
            config.sops.secrets."users/${username}/restic-${hostname}-local-${jobsCfg.label}".path;
          paths = jobsCfg.paths;
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 5"
            "--keep-monthly 12"
            "--keep-yearly 10"
            "--group-by tags"
          ];
          repository = "/run/media/${username}/${vol_label}/${hostname}/${jobsCfg.label}";
          runCheck = true;
          # run backups when the removable disk is mounted, not on a schedule
          timerConfig = null;
          user = "${jobsCfg.user}";
          # DO A RESTIC BACKUP DIRECTLY TO CLOUD USING RCLONE
          # "${hostname}-${username}-b2" = {
          #   inherit
          #     checkOpts
          #     createWrapper
          #     home_exclude
          #     inhibitsSleep
          #     initialize
          #     pruneOpts
          #     timerConfig
          #     ;
          #   exclude = home_exclude;
          #   extraBackupArgs = "${extraBackupArgs}" ++ [ "rclone.connections=100" ];
          #   passwordFile = config.sops.secrets."users/${username}/restic-${hostname}-${username}-b2".path;
          #   paths = [
          #     "${home}"
          #   ]
          #   ++ optionalString config.mettavi.system.services.paperless-ngx.enable [
          #     "${config.services.paperless.dataDir}/export"
          #   ];
          #
          #   repository = "rclone:b2:${hostname}-${username}";
          #   rcloneConfigFile = "${config.home-manager.users.${username}.sops.templates."rclone.conf".path}";
          #   rcloneOptions = {
          #     checkers = 100;
          #     fast-list = true;
          #     # restic already keeps deleted files
          #     b2-hard-delete = true;
          #     log-file = "${logfile}";
          #     max-backlog = 10000;
          #     order-by = "size,mixed,75";
          #     stats = "2m";
          #     transfers = 100;
          #     verbose = true;
          #   };
          #   # checks are resource-intensive in backblaze b2, so do not run a check every time
          #   runCheck = false;
          #   # need to test this (some files may be owned by root)
          #   user = "${username}";
          # };
        }) cfg.jobs;
    };
    sops.secrets = {
      # encryption password for local home backup
      "users/${username}/restic-${hostname}-local-home" = resticSecrets;
      # encryption password for local root backup
      "users/${username}/restic-${hostname}-local-sys" = resticSecrets;
      # encryption password for cloud backup to backblaze b2
      "users/${username}/restic-${hostname}-${username}-b2" = resticSecrets;
    };
    systemd.services = {
      "${hostname}-local-root" = {
        unitConfig = {
          Description = "Run a backup whenever the device is plugged in (and mounted)"; # See https://bbs.archlinux.org/viewtopic.php?id=207050
          # RequiresMountsFor = "/run/media/xxx/Seagate Backup";
          # or use the ConditionPathIsMountPoint= option?
          # See https://unix.stackexchange.com/questions/281650/systemd-unit-requiresmountsfor-vs-conditionpathisdirectory
          # and https://www.mavjs.org/post/automatic-backup-restic-systemd-service/
          ConditionPathIsMountPoint = "/run/media/${username}/${vol_label}/${hostname}/sys";
          # or perhaps WantedBy= option?
        };
        serviceConfig = {
          # ensure it is not considered "started" until after the main process EXITS
          # this means that following services do not start until the this process is COMPLETE
          Type = "oneshot";
        };
      };
      "${hostname}-local-${username}" = {
        unitConfig = {
          After = "${hostname}-local-sys.service";
          Description = "Run a user backup whenever the device is plugged in (and mounted)";
          # See https://bbs.archlinux.org/viewtopic.php?id=207050
          # RequiresMountsFor = "/run/media/xxx/Seagate Backup";
          # or use the ConditionPathIsMountPoint= option?
          # See https://unix.stackexchange.com/questions/281650/systemd-unit-requiresmountsfor-vs-conditionpathisdirectory
          # and https://www.mavjs.org/post/automatic-backup-restic-systemd-service/
          ConditionPathIsMountPoint = "/run/media/${username}/${vol_label}/${hostname}/home";
          # or perhaps WantedBy= option?
        };
      };
    };
  };
}
