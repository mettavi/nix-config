{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "nix-undo" ''
      #!/usr/bin/env bash

      # 1. Find the ID of the latest 'git-pre-safety' snapshot
      # We sort by ID and take the last one
      SNAP_ID=$(snapper -c adminhome list --userdata type=git-pre-safety | tail -n 1 | awk '{print $1}')

      if [ -z "$SNAP_ID" ] || [ "$SNAP_ID" == "ID" ]; then
          echo "❌ No pre-commit safety snapshots found!"
          exit 1
      fi

      echo "🔍 Found safety snapshot ID: $SNAP_ID"
      echo "⚠️ This will revert all changes in /home/${username} to this state."
      read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Aborted."
          exit 0
      fi

      # 2. Undo the changes
      # 'undochange' is better than 'rollback' for home directories 
      # because it doesn't require a reboot.
      echo "🔄 Reverting files..."
      sudo snapper -c adminhome undochange $SNAP_ID..0

      # 3. Reset Git state
      # If the commit actually went through, we need to move the Git pointer back
      echo "🌿 Resetting Git index..."
      git reset --soft HEAD~1

      echo "✅ Rollback complete. Your files and Git are back to the pre-commit state."
    '')
  ];

  # Add this to the // { ... } block in systemd.services
  systemd.services = {
    snapper-cleanup-git-safety = {
      description = "Cleanup old Git safety snapshots";
      path = with pkgs; [
        snapper
        coreutils
        gawk
        xargs
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        echo "Cleaning up old Git safety snapshots for adminhome..."

        # 1. List all git-pre-safety IDs
        # 2. Exclude the most recent 20 (change this number to your preference)
        # 3. Delete the rest
        OLD_IDS=$(snapper -c adminhome list --userdata type=git-pre-safety | \
                  awk '/^[ ]*[1-9]/ {print $1}' | \
                  head -n -20)

        if [ -n "$OLD_IDS" ]; then
          echo "Deleting snapshots: $OLD_IDS"
          # xargs runs 'snapper delete' for each ID found
          echo "$OLD_IDS" | xargs -n 1 snapper -c adminhome delete
        else
          echo "No old safety snapshots to clean up."
        fi
      '';
    };
    systemd.timers.snapper-cleanup-git-safety = {
      description = "Daily cleanup of Git safety snapshots";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
