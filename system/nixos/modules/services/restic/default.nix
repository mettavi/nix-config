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

  # SHARED SETTINGS FOR EVERY RESTIC CONFIGURATION
  commonConfig = {
    checkOpts = [
      "--with-cache" # just to make checks faster
      "--read-data" # also check integrity of the actual data
    ];
    createWrapper = true;
    extraBackupArgs = [
      "--tag ${hostname}"
    ];
    # Prevent the system from sleeping while backing up
    inhibitsSleep = true;
    # create the repo if it doesn't exist
    initialize = true;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--keep-yearly 10"
      "--group-by tags"
    ];
    runCheck = true;
    # run backups when the removable disk is mounted, not on a schedule
    timerConfig = null;
  };

  # Filter only the backup jobs where 'enable = true'
  enabledJobs = filterAttrs (name: job: job.enable) cfg.jobs;

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
          sync ${config.services.restic.backups."${hostname}-home".repository} b2:${hostname}-${username}/
      '';

  resticSecrets = {
    sopsFile = "${secrets_path}/secrets/apps/restic.yaml";
  };

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
        attrsOf (submodule {
          options = {
            enable = mkOption {
              type = bool;
              default = true;
              description = "Whether to enable this backup job";
            };
            localConfig = mkOption {
              type = types.attrs;
              default = { };
              description = "Local job config options that override the defaults";
            };
            vol_label = mkOption {
              type = types.str;
              default = "nixbak";
              description = "The volume label of the backup device (eg. 'luks-samt7')";
            };
            user = mkOption {
              type = str;
              default = "root";
              description = "The user to run the backup job as";
            };
            volumes = mkOption {
              type = attrsOf (submodule {
                options = {
                  enable = mkOption {
                    type = bool;
                    default = true;
                    description = "Whether to backup from this partition/subvolume";
                  };
                  exclusions = mkOption {
                    type = listOf str;
                    description = "A list of paths to exclude from the partition/subvolume backup";
                  };
                  mount = mkOption {
                    type = path;
                    description = "The mount path of the partition/subvolume";
                  };
                  paths = mkOption {
                    type = listOf path;
                    description = "A list of paths to backup from the partition/subvolume";
                  };
                };
              });
            };
          };
        });
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libnotify # Library that sends desktop notifications
      # CHECK: not sure if this is required
      rclone # sync files and directories to and from major cloud storage
      restic-rcl-b2
    ];

    services.restic = {
      backups = mapAttrs (
        job: jobsCfg:
        commonConfig
        // job.localConfig
        // {
          # -r creates the snapshot read-only
          backupPrepareCommand = ''
            btrfs subvolume snapshot -r /home ${snapshots}/home
            btrfs subvolume snapshot -r / ${snapshots}/sys
            ${pkgs.restic}/bin/restic unlock
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
          passwordFile = config.sops.secrets."users/${username}/restic-${hostname}-${jobsCfg.label}".path;
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
        }
      ) cfg.jobs;
    };

    sops.secrets = concatMapAttrs (key: value: {
      # encryption password for each restic backup job
      "users/${username}/restic-${hostname}-${value.label}" = resticSecrets;
    }) cfg.jobs;

    systemd.services =
      let
        Description = "Run a backup whenever the device is plugged in (and mounted)"; # See https://bbs.archlinux.org/viewtopic.php?id=207050
        # RequiresMountsFor = "/run/media/xxx/Seagate Backup";
        # or use the ConditionPathIsMountPoint= option?
        # See https://unix.stackexchange.com/questions/281650/systemd-unit-requiresmountsfor-vs-conditionpathisdirectory
        # and https://www.mavjs.org/post/automatic-backup-restic-systemd-service/
        # See https://bbs.archlinux.org/viewtopic.php?id=207050
        # ConditionPathIsMountPoint = "/run/media/${username}/${vol_label}";
        # or perhaps WantedBy= option?
        ConditionPathIsMountPoint = "/run/media/${username}/${vol_label}";
        # ensure it is not considered "started" until after the main process EXITS
        # this means that following services do not start until the this process is COMPLETE
        serviceConfig = {
          Type = "oneshot";
        };
      in
      mkMerge [
        {
          "restic-backups-${hostname}-sys" = {
            unitConfig = {
              inherit Description ConditionPathIsMountPoint;
              OnFailure = "notify-backup-failed-sys.service";
            };
            inherit serviceConfig;
          };
          "restic-backups-${hostname}-home" = {
            unitConfig = {
              inherit Description ConditionPathIsMountPoint;
              After = mkForce "${hostname}-sys.service";
              OnFailure = "notify-backup-failed-home.service";
            };
            inherit serviceConfig;
          };
        }
        # send desktop notifications about failed backups using libnotify
        # ref: https://www.arthurkoziel.com/restic-backups-b2-nixos/
        (concatMapAttrs (key: value: {
          "notify-backup-failed.${value.label}" = {
            enable = true;
            description = "Notify on failed backup";
            serviceConfig = {
              Type = "oneshot";
              User = "${username}";
            };
            # required for notify-send
            environment.DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${
              toString config.users.users.${username}.uid
            }/bus";
            script = ''
              ${pkgs.libnotify}/bin/notify-send --urgency=critical \
                "Backup failed" \
                "$(journalctl -u restic-backups-${hostname}-${value.label} -n 5 -o cat)"
            '';
          };
        }) cfg.jobs)
      ];
  };
}
