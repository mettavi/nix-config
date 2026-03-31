{
  config,
  hostname,
  lib,
  pkgs,
  secrets_path,
  utils,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.restic;

  backup-now = pkgs.writeShellScriptBin "backup-now" ''
    # If no argument is provided, show available jobs
    if [ -z "$1" ]; then
      echo "Usage: backup-now <job-name>"
      echo "Available jobs:"
      # lists all configured Restic jobs so you don't have to remember the exact names
      systemctl list-unit-files "restic-backups-*" --all --no-legend | awk '{print $1}' | sed 's/restic-backups-//g' | sed 's/.service//g'
      exit 1
    fi

    JOB_NAME="restic-backups-$1.service"

    echo "🚀 Triggering backup job: $1..."

    # We use sudo because systemd backup services are system-level
    sudo systemctl start "$JOB_NAME"

    echo "✅ Job started. You can follow the logs with:"
    echo "   journalctl -u $JOB_NAME -f"
  '';

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

  # create an rclone shell script
  sync-b2 =
    pkgs.writeShellScriptBin "sync-b2.sh" # bash
      ''
        # If no argument is provided, show available jobs
        if [ -z "$1" ]; then
          echo "Usage: rclone-b2.sh <job-name>"
          echo "Available jobs:"
          # lists all configured Restic jobs so you don't have to remember the exact names
          systemctl list-unit-files "restic-backups-*" --all --no-legend | awk '{print $1}' | sed 's/restic-backups-//g' | sed 's/.service//g'
          exit 1
        fi

        JOB_NAME="rclone-sync-$1.service"

        echo "🚀 Triggering rclone sync job: $1..."

        # We use sudo because systemd rclone services are system-level
        sudo systemctl start "$JOB_NAME"

        echo "✅ Job started. You can follow the logs with:"
        echo "   journalctl -u $JOB_NAME -f"
      '';
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
                    type = listOf str;
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
      backup-now
      libnotify # Library that sends desktop notifications
      # CHECK: not sure if this is required
      rclone # sync files and directories to and from major cloud storage
      sync-b2
    ];

    services.restic = {
      backups = mapAttrs (
        name: job:
        let
          isDiskJob = job.vol_label != "";

          btrfsCommands = concatMapAttrsStringSep "\n" (
            vol: pth:
            optionalString pth.enable "${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r ${pth.mount} ${pth.mount}/${vol}"
          ) job.volumes;

          # The actual mount point (parent of the repo folder)
          mountPath = "/run/media/${username}/${job.vol_label}";

          pidFile = "/run/user/$(id -u ${username})/restic-progress-${name}.pid";

          # Logic specifically for USB/Disk jobs
          diskPrepare = # bash
            ''
              # 1. MOUNT GUARD: Check if the path is actually a mount point
              if ! ${pkgs.util-linux}/bin/mountpoint -q "${mountPath}"; then
                echo "ERROR: ${mountPath} is not a mount point. Aborting to save root partition."
                exit 1 # Exit with 1 so systemd knows the 'preparation' failed
              fi

              USER_ID=$(id -u ${username})
              # 2. PROMPT
              if sudo -u ${username} \
                 DISPLAY=:0 \
                 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
                 ${pkgs.zenity}/bin/zenity --question --title="Backup: ${name}" \
                 --text="USB Disk '${job.vol_label}' detected. Start backup?" --timeout=30; then
                
                ${btrfsCommands}
                ${pkgs.restic}/bin/restic unlock

                # 3. PULSING PROGRESS BAR
                sudo -u ${username} \
                   DISPLAY=:0 \
                   DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
                   ${pkgs.zenity}/bin/zenity --progress --pulsate \
                   --title="Restic Backup" \
                   --text="Backing up to ${job.vol_label}..." \
                   --no-cancel --auto-close & 
                
                echo $! > ${pidFile}
              else
                echo "User cancelled or timeout."
                exit 0
              fi
            '';

          # Logic for Cloud/Other jobs (No popup, just snapshots)
          cloudPrepare = # bash
            ''
              ${btrfsCommands}
              ${pkgs.restic}/bin/restic unlock
            '';

        in
        commonConfig
        // job.localConfig
        // {
          # -r creates the snapshot read-only
          # Choose the right preparation script based on job type
          backupPrepareCommand = if isDiskJob then diskPrepare else cloudPrepare;
          backupCleanupCommand = concatMapAttrsStringSep "\n" (
            vol: pth:
            optionalString pth.enable "${pkgs.btrfs-progs}/bin/btrfs subvolume delete ${pth.mount}/${vol}"
          ) job.volumes;
          # Patterns to exclude when backing up
          exclude = concatLists (
            mapAttrsToList (
              vol: pth:
              if pth.enable then
                map (exc: replaceStrings [ "//" ] [ "/" ] "${pth.mount}/${vol}/${exc}") pth.exclusions
              else
                [ ]
            ) job.volumes
          );
          passwordFile = config.sops.secrets."users/${username}/restic-${name}".path;
          # paths to actually back up
          paths = concatLists (
            mapAttrsToList (
              vol: pth:
              if pth.enable then
                map (p: replaceStrings [ "//" ] [ "/" ] "${pth.mount}/${vol}/${p}") pth.paths
              else
                [ ]
            ) job.volumes
          );
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
      # LAYER 1: Base configuration for ALL enabled jobs
      (mapAttrs' (
        name: job:
        nameValuePair "restic-backups-${name}" {
          # Universal notification triggers
          onSuccess = [ "notify-backup-success-${name}.service" ];
          onFailure = [ "notify-backup-failed-${name}.service" ];
        }
      ) enabledJobs)

      # LAYER 2: Extra "Mount Logic" specifically for USB disk jobs
      (mapAttrs' (
        name: job:
        nameValuePair "restic-backups-${name}" {
          # bindsTo tells systemd: "The thing I depend on is gone, I should stop immediately."
          bindsTo = [ "${utils.escapeSystemdPath job.repo}.mount" ];
          after = [ "${utils.escapeSystemdPath job.repo}.mount" ];
          wantedBy = [ "${utils.escapeSystemdPath job.repo}.mount" ];
        }
      ) diskJobs)

      # LAYER 3: The Success Notification Service definition
      (mapAttrs' (
        name: job:
        nameValuePair "notify-backup-success-${name}" {
          enable = true;
          description = "Notify on successful backup";
          serviceConfig = {
            Type = "oneshot";
            User = "${username}";
          };
          script = ''
            USER_ID=$(id -u ${username})
            sudo -u ${username} \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
            ${pkgs.libnotify}/bin/notify-send --urgency=low \
              "Backup Complete" \
              "Restic job '${name}' finished successfully."
          '';
        }
      ) enabledJobs)

      # LAYER 4: The Failure Notification Service definition
      # send desktop notifications about failed backups using libnotify
      # ref: https://www.arthurkoziel.com/restic-backups-b2-nixos/
      (mapAttrs' (
        name: job:
        nameValuePair "notify-backup-failed-${name}" {
          enable = true;
          description = "Notify on failed backup";
          serviceConfig = {
            Type = "oneshot";
            User = "${username}";
          };
          script = ''
            # Find the primary user's ID (assuming the one you defined in your module)
            USER_ID=$(id -u ${username})

            # Run notify-send as that user, pointing to their DBus session
            # This allows a system-root process to "talk" to your desktop
            sudo -u ${username} \
            DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
            ${pkgs.libnotify}/bin/notify-send --urgency=critical \
              "Backup failed" \
              "$(journalctl -u restic-backups-${name} -n 5 -o cat)"
          '';
        }
      ) enabledJobs)

      (mapAttrs' (
        name: job:
        nameValuePair "rclone-sync-${name}" {
          enable = true;
          description = "Sync backups to the cloud with rclone";
          serviceConfig = {
            Type = "oneshot";
            User = "${username}";
          };
          script = ''
            logfile_dir = "$XDG_STATE_HOME/logs/rclone"
            logfile = "$logfile_dir/restic-${hostname}.log"

            # create the base directory if it doesn't exist
            if [ ! -d $logfile_dir ]; then
              echo "Creating $logfile_dir..."
              mkdir -p $logfile_dir 
            else
              echo "$logfile_dir already exits"
            fi

            # copy the local restic backup to the cloud (backblaze b2)
            rclone --log-level INFO --log-file=$logfile \
              --verbose --b2-hard-delete --checkers 100 --transfers 100 --stats 2m --order-by size,mixed,75 --max-backlog 10000 --progress --retries 1 --fast-list \
              sync "${job.repo}/${name}" b2:${hostname}/restic/
          '';
        }
      ) enabledJobs)
    ];
  };
}
