{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.snapper;

  # Filter only the mounts where 'enable = true'
  enabledMounts = filterAttrs (name: mount: mount.enable) cfg.mounts;
in
{
  # --- SNAPPER HEALTH CHECK ---
  systemd.services.snapper-health-check = {
    description = "Check if snapper snapshots are being created regularly";
    onFailure = [ "snapper-alert.service" ];
    path = with pkgs; [
      coreutils
      findutils
      gawk
      gnugrep
      snapper
    ];
    serviceConfig.Type = "oneshot";

    script = ''
      echo "Starting Snapper health check..."
      EXIT_CODE=0
      CURRENT_TIME=$(date +%s)
      MAX_AGE=$((24 * 3600)) # 24 hours in seconds

      ${concatStringsSep "\n" (
        mapAttrsToList (name: m: ''
          echo "Checking config: ${name}..."

          # Get the timestamp of the newest snapshot (last line of snapper list)
          LAST_SNAP_TIME=$(snapper -c ${name} list | awk -F '|' '/^[ ]*[1-9]/ { print $4 }' | tail -n 1 | xargs)

          if [ -z "$LAST_SNAP_TIME" ]; then
            echo "ERROR: No snapshots found for ${name}!"
            EXIT_CODE=1
          else
            # Convert Snapper time to epoch
            LAST_SNAP_EPOCH=$(date -d "$LAST_SNAP_TIME" +%s)
            AGE=$((CURRENT_TIME - LAST_SNAP_EPOCH))

            if [ "$AGE" -gt "$MAX_AGE" ]; then
              echo "ERROR: Latest snapshot for ${name} is $((AGE / 3600)) hours old!"
              EXIT_CODE=1
            else
              echo "OK: Latest snapshot for ${name} is $((AGE / 60)) minutes old."
            fi
          fi
        '') enabledMounts
      )}

      exit $EXIT_CODE
    '';
  };

  # Run the health check every 4 hours
  systemd.timers.snapper-health-check = {
    description = "Timer for Snapper health check";
    timerConfig = {
      OnBootSec = "15min";
      OnUnitActiveSec = "4h";
    };
    wantedBy = [ "timers.target" ];
  };

  # A helper service to send desktop alerts from the system level
  systemd.services.snapper-alert = {
    description = "Send desktop notification on snapper failure";
    path = with pkgs; [
      libnotify
      procps
      coreutils
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      # Find the primary user's ID (assuming the one you defined in your module)
      USER_ID=$(id -u ${username})

      # Run notify-send as that user, pointing to their DBus session
      # This allows a system-root process to "talk" to your desktop
      sudo -u ${username} \
        DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus \
        notify-send -u critical "Snapper Health Alert" "Snapshots have not been created in over 24 hours! Check 'journalctl -u snapper-health-check'"
    '';
  };
}
