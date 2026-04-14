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

  # 1. Define all your custom tools in one place
  scriptDefinitions = {
    "backup-now" = {
      type = "trigger";
      prefix = "restic-backups-";
      description = "Restic backup";
    };
    "sync-b2" = {
      type = "trigger";
      prefix = "rclone-sync-";
      description = "Rclone cloud sync";
    };
    "backup-status" = {
      type = "status";
      prefixes = [
        "restic-backups-"
        "rclone-sync-"
      ];
      description = "Backup & Sync Status";
    };
  };

  # 2. The "Factory" function that builds the scripts
  makeCustomScript =
    name: conf:
    pkgs.writeShellScriptBin name (
      if conf.type == "trigger" then # bash
        ''
          # --- TRIGGER SCRIPT LOGIC ---
          if [ -z "$1" ]; then
            echo "Usage: ${name} <job-name>"
            echo "Available ${conf.description} jobs:"
            ${pkgs.systemd}/bin/systemctl list-unit-files "${conf.prefix}*" --no-legend | \
              ${pkgs.gawk}/bin/awk '{print $1}' | ${pkgs.gnused}/bin/sed 's/${conf.prefix}//g' | ${pkgs.gnused}/bin/sed 's/.service//g'
            exit 1
          fi

          JOB_NAME="${conf.prefix}$1.service"
          echo "🚀 Triggering ${conf.description}: $1..."
          sudo ${pkgs.systemd}/bin/systemctl start "$JOB_NAME"
          echo "✅ Job started. Follow logs with: journalctl -u $JOB_NAME -f"
        ''
      else
        ''
          # --- STATUS SCRIPT LOGIC ---
          echo "--- ${conf.description} ---"
          printf "%-30s %-20s %-10s\n" "UNIT" "LAST EXIT" "RESULT"
          echo "----------------------------------------------------------------------"

          # Iterate through all specified prefixes
          for prefix in ${builtins.concatStringsSep " " conf.prefixes}; do
            for unit in $(${pkgs.systemd}/bin/systemctl list-unit-files "$prefix*" --no-legend | ${pkgs.gawk}/bin/awk '{print $1}'); do
              # Extract the timestamp and the last result (success/failed/etc)
              INFO=$(${pkgs.systemd}/bin/systemctl show "$unit" --property=InactiveExitTimestamp --property=Result --value | ${pkgs.coreutils}/bin/tr '\n' ' ')
              printf "%-30s %-20s\n" "$unit" "$INFO"
            done
          done
        ''
    );

  # Reusable notification helper
  mkNotify =
    {
      title,
      msg,
      urgency ? "normal",
      icon ? "info",
      runAsUser ? null,
      action ? null, # e.g., "view_log=View Log"
      timeout ? null,
    }:
    let
      # Use a bash subshell to generate a timestamp (e.g., 20:45:10)
      timestamp = "$(date +'%H:%M:%S')";

      # Construct optional flags
      actionFlag = if action != null then "--action='${action}'" else "";
      timeoutFlag = if timeout != null then "-t ${toString timeout}" else "";

      # We use double quotes for the title so Bash can expand the $(date) subshell
      notifyCmd = "${pkgs.libnotify}/bin/notify-send ${actionFlag} ${timeoutFlag} --urgency=${urgency} --icon=${icon} --app-name='Restic' \"${title} [${timestamp}]\" '${msg}'";
    in
    if runAsUser == null then
      # Version for services already running as the user (e.g., rclone)
      # bash
      ''
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
        eval ${notifyCmd}
      ''
    else
      # Version for root services needing to notify a user (e.g., restic)
      # bash
      ''
        # Find the primary user's ID
        USER_ID=$(id -u ${runAsUser})
        # Run notify-send as that user, pointing to their DBus session
        # This allows a system-root process to "talk" to your desktop
        /run/wrappers/bin/sudo -u ${runAsUser} \
          DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
          XDG_RUNTIME_DIR=/run/user/$USER_ID \
          /bin/sh -c ${lib.escapeShellArg notifyCmd}
      '';

  # 3. Map the definitions into a list of packages
  customScripts = lib.mapAttrsToList (name: conf: makeCustomScript name conf) scriptDefinitions;

  # SHARED SETTINGS FOR EVERY RESTIC CONFIGURATION
  commonConfig = {
    checkOpts = [
      "--with-cache" # just to make checks faster
    ];
    createWrapper = true;
    extraBackupArgs = [
      "--tag ${hostname}"
    ];
    # Prevent the system from sleeping while backing up
    inhibitsSleep = true;
    # create the repo if it doesn't exist
    initialize = true;
    # Use a wrapper to pass the parent id to workaround problem with --files-from flag discussed at
    # https://github.com/restic/restic/issues/2246
    package = pkgs.writeShellScriptBin "restic" ''
      # If the command is 'backup', we inject our parent logic
      if [[ "$1" == "backup" ]]; then
        shift # remove 'backup' from the argument list
        
        echo "Custom Wrapper: Determining latest snapshot for --parent..."
        
        # Extract the ID of the latest snapshot
        # We use --quiet to avoid extra noise in the JSON output
        PARENT_ID=$(${pkgs.restic}/bin/restic --json snapshots --quiet | \
          ${pkgs.jq}/bin/jq -r 'try max_by(.time) | .short_id // empty')

        if [ -n "$PARENT_ID" ]; then
          echo "Custom Wrapper: Using parent snapshot $PARENT_ID"
          exec ${pkgs.restic}/bin/restic backup --parent "$PARENT_ID" "$@"
        else
          echo "Custom Wrapper: No existing snapshots found. Starting fresh."
          exec ${pkgs.restic}/bin/restic backup "$@"
        fi
      else
        # For all other commands (unlock, check, etc.), execute normally
        exec ${pkgs.restic}/bin/restic "$@"
      fi
    '';
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--keep-yearly 10"
      "--group-by tags"
    ];
    runCheck = false;
    # run backups when the removable disk is mounted, not on a schedule
    timerConfig = null;
  };

  # Filter only the backup jobs where 'enable = true'
  enabledJobs = filterAttrs (name: job: job.enable) cfg.jobs;

  # Filter jobs that backup to a removable disk
  diskJobs = filterAttrs (name: job: job.vol_label != "") cfg.jobs;

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
            checkParts = mkOption {
              type = int;
              default = 7;
              description = "Number of subsets to divide the restic repo into for rotating checks (e.g. 7 for weekly, 365 for yearly)";
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
    environment.systemPackages =
      with pkgs;
      [
        libnotify # Library that sends desktop notifications
        rclone # sync files and directories to and from major cloud storage
      ]
      ++ customScripts; # Merge the generated scripts into your packages

    services.restic = {
      backups = mapAttrs (
        name: job:
        commonConfig
        // job.localConfig
        // {
          # NB: this command has been moved to serviceConfig.ExecCondition, see below
          # backupPrepareCommand = if isDiskJob then diskPrepare else cloudPrepare;
          backupCleanupCommand =
            "${pkgs.systemd}/bin/systemctl stop postgres-backup-session.service"
            + "\n\n"
            + concatMapAttrsStringSep "\n" (
              vol: pth:
              let
                # the escaped mount point of the pre-backup snapshot
                subvolMount = replaceStrings [ "//" ] [ "/" ] "${pth.mount}/${vol}";
              in
              optionalString pth.enable ''
                if [ -e ${subvolMount} ]; then 
                 ${pkgs.btrfs-progs}/bin/btrfs subvolume delete ${subvolMount}
                fi
              ''
            ) job.volumes
            + "\n"
            # bash
            + ''
              # WAL Archive Cleanup
              # Keep the 5th most recent label, effectively keeping ~5 hours of logs
              ARCHIVE_DIR="/var/backup/postgresql/archive"
              OLDEST_BACKUP_FILE=$(ls -1t $ARCHIVE_DIR/*.backup 2>/dev/null | sed -n '5p')

              if [ -n "$OLDEST_BACKUP_FILE" ]; then
                # Extract just the filename for pg_archivecleanup
                CLEANUP_TARGET=$(basename "$OLDEST_BACKUP_FILE")
                ${config.services.postgresql.package}/bin/pg_archivecleanup -d "$ARCHIVE_DIR" "$CLEANUP_TARGET"
              fi
            '';

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
        let
          isDiskJob = (job.vol_label != "");

          pgCommands =
            let
              dbs = config.services.postgresqlBackup.databases;
            in
            concatMapStringsSep "\n" (
              db: "${pkgs.systemd}/bin/systemctl start postgresqlBackup-${db}.service"
            ) dbs
            # Tell Postgres to prepare for a physical backup
            # This forces a checkpoint and ensures the files are ready for snapping.
            # + "\n${config.services.postgresql.package}/bin/psql -U postgres -c \"SELECT pg_backup_start('restic-snapshot');\""
            + "\n"
            +
              # bash
              ''
                ${pkgs.systemd}/bin/systemctl start postgres-backup-session.service
                # Give Postgres 3-5 seconds to finish the backup_start checkpoint
                sleep 5
              '';

          # -r creates the snapshot read-only
          btrfsCommands = concatMapAttrsStringSep "\n" (
            vol: pth:
            let
              # the escaped mount point of the subvolume snapshot
              subvolMount = replaceStrings [ "//" ] [ "/" ] "${pth.mount}/${vol}";
            in
            optionalString pth.enable "${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r ${pth.mount} ${subvolMount}"
          ) job.volumes;

          # The actual mount point (parent of the repo folder)
          mountPath = "/run/media/${username}/${job.vol_label}";

          # Logic specifically for USB/Disk jobs
          diskPrepare =
            pkgs.writeShellScriptBin "diskPrepare" # bash
              ''
                # 1. MOUNT GUARD: Check if the path is actually a mount point
                if ! ${pkgs.util-linux}/bin/mountpoint -q "${mountPath}"; then
                  echo "ERROR: ${mountPath} is not a mount point. Aborting to save root partition."
                  # Exit with 255 so systemd "ExecCondition" knows the 'preparation' failed
                  exit 255
                fi

                # 1. Identify the user's environment
                # We need to tell Zenity WHERE to show up.
                USER_ID=$(id -u ${username})

                # 2. AUTO-DETECT WAYLAND SOCKET
                # This finds wayland-0, wayland-1, etc., dynamically
                WAYLAND_SOCKET=$(ls /run/user/$USER_ID/wayland-* | head -n 1 | xargs basename)

                # We define the Wayland environment once to keep things clean
                # Note: wayland-0 is the default for the first logged-in user
                # We add DBUS_SESSION_BUS_ADDRESS explicitly to fix the "Transport" error
                WAYLAND_ENV="WAYLAND_DISPLAY=$WAYLAND_SOCKET XDG_RUNTIME_DIR=/run/user/$USER_ID XDG_CURRENT_DESKTOP=GNOME GDK_BACKEND=wayland XDG_SESSION_TYPE=wayland DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus"

                # 2. Run Zenity as the user and capture the exit code
                # --question: creates a Yes/No dialog
                # --timeout: automatically continues after 30 seconds
                # NB: USE THE SUDO WRAPPER ON NIXOS, because "sudo needs setuid to work, 
                # but the package itself in nixpkgs can’t have it"
                if /run/wrappers/bin/sudo -u ${username} env $WAYLAND_ENV \
                   ${pkgs.zenity}/bin/zenity --question --title="Backup: ${name}" \
                   --text="USB Disk '${job.vol_label}' detected. Start backup?" --timeout=30; then

                  ZEN_EXIT=$?
                else
                  ZEN_EXIT=$?
                fi  

                # 3. Evaluate the Exit Code
                # 0 = Yes, 5 = Timeout. We proceed for both.
                if [ "$ZEN_EXIT" -eq 0 ] || [ "$ZEN_EXIT" -eq 5 ]; then
                  if [ "$ZEN_EXIT" -eq 5 ]; then
                    echo "Zenity timed out. Proceeding with backup by default..."
                  else
                    echo "User clicked YES. Starting backup..."
                  fi
                  
                  ${pgCommands}
                  ${btrfsCommands}
                  ${pkgs.restic}/bin/restic unlock

                else
                  # If exit code is 1 (User clicked NO) or anything else (ESC/Closed window), exit with status 1
                  # inside a systemd "ExecCondition" (see below) so the service doesn't "fail," it just skips.
                  echo "User explicitly cancelled (Exit Code: $ZEN_EXIT). Skipping backup."
                  exit 1
                fi
              '';
          # Logic for Cloud/Other jobs (No popup, just snapshots)
          cloudPrepare = # bash
            ''
              ${pgCommands}
              ${btrfsCommands}
              ${pkgs.restic}/bin/restic unlock
            '';
        in
        nameValuePair "restic-backups-${name}" {
          serviceConfig = {
            # ExecCondition: with exit code 1 through 254 (inclusive),
            # the remaining commands are skipped but the unit is not marked as failed
            # Choose the right preparation script based on job type
            ExecCondition = if isDiskJob then "${diskPrepare}/bin/diskPrepare" else cloudPrepare;
          };
          # Universal notification triggers
          onSuccess = [
            "notify-backup-success-${name}.service"
            "restic-check-${name}.service"
          ];
          onFailure = [ "notify-backup-failed-${name}.service" ];
        }
      ) enabledJobs)

      {
        "postgres-backup-session" = {
          description = "Persistent PostgreSQL backup session";
          # Ensure we only start after the main DB is ready
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
          serviceConfig = {
            Type = "simple";
            User = "postgres";
            Group = "postgres";
            # This ensures /run/postgresql-backup exists for our pipe
            RuntimeDirectory = "postgresql-backup";
            # This ensures the service can see the real Postgres socket
            BindReadOnlyPaths = [ "/run/postgresql" ];

            ExecStart = pkgs.writeShellScript "pg-session" ''
              set -e

              PIPE="/run/postgresql-backup/session.pipe"
              [ -p "$PIPE" ] || mkfifo "$PIPE"

              # Wait for the actual Postgres socket to appear before starting psql
              until [ -S /run/postgresql/.s.PGSQL.5432 ]; do
                echo "Waiting for postgres socket..."
                sleep 1
              done

              # Start psql reading from the pipe
              # We use 'tail -f' to feed 'psql' so the session stays open
              ${pkgs.coreutils}/bin/tail -f "$PIPE" | ${config.services.postgresql.package}/bin/psql -U postgres &
              PSQL_PID=$!

              # Start the backup
              sleep 1
              echo "SELECT pg_backup_start('restic-session');" > "$PIPE"

              # Keep the script running until systemd sends SIGTERM
              trap "echo 'SELECT pg_backup_stop();' > \"$PIPE\"; kill $PSQL_PID; exit 0" SIGTERM SIGINT
                    
              wait $PSQL_PID
            '';
          };
        };
      }

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
          script = mkNotify {
            runAsUser = username; # This triggers the sudo wrapper
            title = "Restic Backup";
            msg = "Job '${name}' finished successfully. You can unplug the drive.";
          };
        }
      ) enabledJobs)

      # LAYER 4: The Failure Notification Service definition
      # send desktop notifications about failed backups using libnotify
      (mapAttrs' (
        name: job:
        nameValuePair "notify-backup-failed-${name}" {
          enable = true;
          description = "Notify on failed backup";
          serviceConfig = {
            Type = "oneshot";
            User = "${username}";
          };
          script = mkNotify {
            runAsUser = username; # This triggers the sudo wrapper
            urgency = "critical";
            icon = "error";
            timeout = 0; # Stays on screen until clicked
            title = "Backup failed";
            # We use a subshell to grab the journal logs for the message
            msg = "$(journalctl -u restic-backups-${name} -n 5 -o cat)";
          };
        }
      ) enabledJobs)

      # LAYER 5: Rotating restic check (read-data-subset cycles through 1/7 ... 7/7)
      (mapAttrs' (
        name: job:
        nameValuePair "restic-check-${name}" {
          enable = true;
          description = "Restic rotating integrity check for ${name}";
          serviceConfig = {
            Type = "oneshot";
            User = job.user;
          };
          environment = {
            RESTIC_REPOSITORY = "${job.repo}/${name}";
          };
          script = ''
            STATE_DIR="/var/lib/restic-check"
            STATE_FILE="$STATE_DIR/${name}.index"
            TOTAL=${toString job.checkParts}

            ${pkgs.coreutils}/bin/mkdir -p "$STATE_DIR"

            # Read the last index, defaulting to 0 if file doesn't exist
            if [ -f "$STATE_FILE" ]; then
              LAST=$(${pkgs.coreutils}/bin/cat "$STATE_FILE")
            else
              LAST=0
            fi

            # Advance, wrapping back to 1 after TOTAL
            NEXT=$(( (LAST % TOTAL) + 1 ))

            echo "Running restic check --read-data-subset ''${NEXT}/''${TOTAL}"
            # fail explicitly, even though "set -e" is auto-added by the nixos script wrapper
            RESTIC_PASSWORD_FILE="${config.sops.secrets."users/${username}/restic-${name}".path}" \
              ${pkgs.restic}/bin/restic check \
                --with-cache \
                --read-data-subset "''${NEXT}/''${TOTAL}" \
                || { echo "restic check failed! Index not advanced."; exit 1; } 

            # Only persist the new index if the check succeeded
            echo "$NEXT" > "$STATE_FILE"
          '';
          # For disk jobs: don't outlive the mount
          bindsTo = lib.optional (job.vol_label != "") "${utils.escapeSystemdPath job.repo}.mount";
          after = lib.optional (job.vol_label != "") "${utils.escapeSystemdPath job.repo}.mount";
        }
      ) enabledJobs)

      (mapAttrs' (
        name: job:
        nameValuePair "rclone-sync-${name}" {
          enable = true;
          description = "Sync backups to the cloud with rclone";
          serviceConfig = {
            # Only run if the repo config is actually reachable
            ExecCondition = "${pkgs.coreutils}/bin/test -f ${job.repo}/${name}/config";
            ExecStopPost =
              pkgs.writeShellScript "notify-rclone-skipped" # bash
                ''
                  # SERVICE_RESULT is set to 'exec-condition' if ExecCondition fails
                  if [ "$SERVICE_RESULT" = "exec-condition" ]; then
                    ${mkNotify {
                      title = "Backup Skipped";
                      msg = "USB Drive not found at ${job.repo}. Sync cancelled.";
                      icon = "drive-harddisk";
                      urgency = "critical";
                      timeout = 0; # Stays on screen until clicked
                    }}
                  fi
                '';
            Type = "oneshot";
            User = "${username}";
            # Systemd creates /var/log/rclone and gives ${username} write access
            LogsDirectory = "rclone";
          };
          script = # bash
            ''
              # Use a timestamp so every backup has its own unique log file
              TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
              LOGFILE="/var/log/rclone/sync-$TIMESTAMP.log"

              # copy the local restic backup to the cloud (backblaze b2)
              ${pkgs.rclone}/bin/rclone --log-level INFO --log-file=$LOGFILE \
                --b2-hard-delete --checkers 100 --transfers 100 \
                --stats 2m --order-by size,mixed,75 --max-backlog 10000 --progress --retries 1 --fast-list \
                sync "${job.repo}/${name}" b2:${hostname}-g14/restic/
            '';
        }
      ) enabledJobs)
    ];

    systemd.timers = mapAttrs' (
      name: job:
      nameValuePair "rclone-sync-${name}" {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          # Run every Monday at 3:00 AM
          OnCalendar = "Monday *-*-* 03:00:00";
          # If the computer was off at 3 AM, run it as soon as we boot up
          Persistent = true;
          # Spread the load (if you have multiple jobs)
          RandomizedDelaySec = "1h";
        };
      }
    ) enabledJobs;

    systemd.tmpfiles.rules = [
      # Type  Path                  Mode  User        Group       Age  Argument
      # clean up the rclone log files periodically
      "d      /var/log/rclone       0755  ${username} root        30d  -"
      # failsafe to fix permissions if necessary (the script already creates the directory)
      "d      /var/lib/restic-check 0700  root        root        -    -"
    ];
  };
}
