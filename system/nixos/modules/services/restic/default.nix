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

  # Filter jobs that backup to a removable disk
  diskJobs = filterAttrs (name: job: job.vol_label != "") cfg.jobs;

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
              type = attrs;
              default = { };
              description = "Local job config options that override the defaults";
            };
            repo = mkOption {
              type = str;
              description = "The restic repository to backup to";
            };
            user = mkOption {
              type = str;
              default = "root";
              description = "The user to run the backup job as";
            };
            vol_label = mkOption {
              type = str;
              default = "";
              description = "The volume label of the backup device (eg. 'luks-samt7')";
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
        name: job:
        commonConfig
        // job.localConfig
        // {
          # -r creates the snapshot read-only
          backupPrepareCommand =
            concatMapAttrsStringSep "\n" (
              vol: pth: optionalString pth.enable "btrfs subvolume snapshot -r ${pth.mount} ${pth.mount}/${vol}"
            ) job.volumes
            + "\n${pkgs.restic}/bin/restic unlock";
          backupCleanupCommand = concatMapAttrsStringSep "\n" (
            vol: pth: optionalString pth.enable "btrfs subvolume delete ${pth.mount}/${vol}"
          ) job.volumes;
          # Patterns to exclude when backing up
          exclude = mapAttrsToList (
            vol: pth: optionalString pth.enable "${pth.mount}/${vol}/${pth.exclusions}"
          ) job.volumes;
          passwordFile = config.sops.secrets."users/${username}/restic-${name}".path;
          paths = mapAttrsToList (
            vol: pth: optionalString pth.enable "${pth.mount}/${vol}/${pth.paths}"
          ) job.volumes;
          repository = "${job.repo}/${name}";
          user = "${job.user}";
        }
      ) enabledJobs;
    };

    sops.secrets = mapAttrs' (
      name: job:
      nameValuePair "users/${username}/restic-${name}" {
        # encryption password for each restic backup job
        sopsFile = "${secrets_path}/secrets/apps/restic.yaml";
      }
    ) enabledJobs;

    systemd.services = mkMerge [
      (mapAttrs' (
        name: job:
        nameValuePair "restic-backups-${name}" {
          description = "Run a backup whenever the device is plugged in (and mounted)"; # See https://bbs.archlinux.org/viewtopic.php?id=207050
          # ensure it is not considered "started" until after the main process EXITS
          # this means that following services do not start until the this process is COMPLETE
          onFailure = [ "notify-backup-failed-${name}.service" ];
          unitConfig = {
            # RequiresMountsFor = "/run/media/xxx/Seagate Backup";
            # or use the ConditionPathIsMountPoint= option?
            # See https://unix.stackexchange.com/questions/281650/systemd-unit-requiresmountsfor-vs-conditionpathisdirectory
            # and https://www.mavjs.org/post/automatic-backup-restic-systemd-service/
            # See https://bbs.archlinux.org/viewtopic.php?id=207050
            # ConditionPathIsMountPoint = "/run/media/${username}/${vol_label}";
            # or perhaps WantedBy= option?
            ConditionPathIsMountPoint = "${job.repo}";
          };
          serviceConfig = {
            Type = "oneshot";
          };
        }
      ) diskJobs)
          };
        }) enabledJobs)
      ];
  };
}
