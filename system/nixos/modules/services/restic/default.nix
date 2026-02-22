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
                  type = listOf path;
                  description = "A list of paths to exclude from the backup";
                };
                paths = mkOption {
                  type = listOf path;
                  description = "A list of paths to backup";
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
      # backup the main user's home directory
      "${hostname}-local-${username}" = {
        enable = true;
        label = "home";
        exclusions = [
          "${snapshots}/home/${username}/.local/share/Trash"
          "${home}/.cache"
          "${home}/Downloads"
          "${home}/.npm"
          "${home}/.local/share/containers"
          "!${home}/.local/share/containers/storage/volumes"
        ];
        paths = [
          "${snapshots}/${username}"
        ];
        user = "${username}";
      };
      # backup important system directories
      "${hostname}-local-root" = {
        enable = true;
        label = "root";
        exclusions = [
          "${snapshots}/root/.cache"
          ".log"
          ".tmp"
          ".Trash"
          "/var/lib/containers"
          "!/var/lib/containers/storage/volumes"
        ];
        paths = [
          "${snapshots}/root/etc/group"
          "/etc/machine-id"
          "/etc/NetworkManager/system-connections"
          "/etc/passwd"
          "/etc/subgid"
          "/root"
          "/var/backup"
          "/var/lib"
        ]
        ++ optionalString config.mettavi.system.services.paperless-ngx.enable [
          "${snapshots}/root/var/lib/paperless/export"
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
        mkIf "${jobsCfg.enable}" {
          backupPrepareCommand.text = ''
            btrfs subvolume snapshot -r /home ${snapshots}/${username}
            btrfs subvolume snapshot -r / ${snapshots}/root
          '';
          backupCleanupCommand.text = ''
            btrfs subvolume delete ${snapshots}/${username}
            btrfs subvolume delete ${snapshots}/root
          '';
          checkOpts = [
            "--with-cache" # just to make checks faster
            "--read-data" # also check integrity of the actual data
          ];
          createWrapper = true;
          # Patterns to exclude when backing up
          exclude = "${jobsCfg.exclusions}";
          extraBackupArgs = [
            "--tag ${hostname}"
          ];
          # Prevent the system from sleeping while backing up
          inhibitsSleep = true;
          # create the repo if it doesn't exist
          initialize = true;
          passwordFile =
            config.sops.secrets."users/${username}/restic-${hostname}-local-${jobsCfg.label}".path;
          paths = "${jobsCfg.paths}";
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
          user = "${jobsCfg.label}";
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
        }
      ) cfg.jobs;
    };
    sops.secrets = {
      # encryption password for local home backup
      "users/${username}/restic-${hostname}-local-${username}" = resticSecrets;
      # encryption password for local root backup
      "users/${username}/restic-${hostname}-local-root" = resticSecrets;
      # encryption password for cloud backup to backblaze b2
      "users/${username}/restic-${hostname}-${username}-b2" = resticSecrets;
    };
    systemd.services = # mapAttrs (
      {
        "${hostname}-local-root" = {
          unitConfig = {
            Description = "Run a backup whenever the device is plugged in (and mounted)"; # See https://bbs.archlinux.org/viewtopic.php?id=207050
            # RequiresMountsFor = "/run/media/xxx/Seagate Backup";
            # or use the ConditionPathIsMountPoint= option?
            # See https://unix.stackexchange.com/questions/281650/systemd-unit-requiresmountsfor-vs-conditionpathisdirectory
            # and https://www.mavjs.org/post/automatic-backup-restic-systemd-service/
            ConditionPathIsMountPoint = "/run/media/${username}/${vol_label}/${hostname}/root";
            # or perhaps WantedBy= option?
          };
          ServiceConfig = {
            # ensure it is not considered "started" until after the main process EXITS
            # this means that following services do not start until the this process is COMPLETE
            Type = "oneshot";
          };
        };
        "${hostname}-local-${username}" = {
          unitConfig = {
            After = "${hostname}-local-root.service";
            Description = "Run a user backup whenever the device is plugged in (and mounted)";
            # See https://bbs.archlinux.org/viewtopic.php?id=207050
            # RequiresMountsFor = "/run/media/xxx/Seagate Backup";
            # or use the ConditionPathIsMountPoint= option?
            # See https://unix.stackexchange.com/questions/281650/systemd-unit-requiresmountsfor-vs-conditionpathisdirectory
            # and https://www.mavjs.org/post/automatic-backup-restic-systemd-service/
            ConditionPathIsMountPoint = "/run/media/${username}/${vol_label}/${hostname}/${username}";
            # or perhaps WantedBy= option?
          };
        };
      };
  };
}
