{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.snapper;
in
{
  options.mettavi.system.services.snapper = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure automatic btrfs snapshots using snapper";
    };
  };

  config = mkIf cfg.enable {
    services.snapper =
      let
        # Any option mentioned in man:snapper-configs(5) is valid here
        commonConfig = {
          FSTYPE = "btrfs"; # Only btrfs is stable and tested.
          ### PERMISSIONS ###
          # List of users/groups allowed to operate with the config.
          # (“root” is always implicitly included)
          ALLOW_USERS = [ "${username}" ];
          ALLOW_GROUPS = [ ];
          # sync above ALLOW users/groups to the acl of the .snapshots directory
          SYNC_ACL = true;

          # The intention of PRE/POST SNAPSHOT PAIRS is to snapshot
          # the filesystem before and after a modification.
          # Whether pre and post snapshots should be compared in the background after creation
          BACKGROUND_COMPARISON = "yes";
          # Whether the empty-pre-post cleanup algorithm should be run,
          # which deletes pre/post snapshot pairs with empty diffs.
          EMPTY_PRE_POST_CLEANUP = "yes";
          EMPTY_PRE_POST_MIN_AGE = "1800"; # Minimal age (secs) for snapshots to be deleted

          ###### NUMBER CLEANUP ALGORITHM ######
          # Deletes old snapshots when a certain number of snapshots is reached.
          NUMBER_CLEANUP = false;
          # Minimal age (secs) for snapshots to be deleted
          NUMBER_MIN_AGE = "1800";
          NUMBER_LIMIT = "50";
          NUMBER_LIMIT_IMPORTANT = "10";

          ###### TIMELINE SNAPSHOTS ######
          TIMELINE_CREATE = true; # Whether hourly snapshots should be created
          # Old snapshots are automatically deleted.
          # By default, the first snapshot of the last ten days, months and years is kept.
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "10";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "0";
          TIMELINE_LIMIT_MONTHLY = "0";
          TIMELINE_LIMIT_YEARLY = "10";
        };
      in
      {
        cleanupInterval = "1d";
        # a list of files that should never be reverted (eg. state info like /etc/mtab)
        # Note that filters do not exclude files or directories from being snapshotted.
        # For that, use subvolumes or mount points.
        filters = "";
        # trigger the snapshot immediately if the last trigger was missed
        persistentTimer = true;
        snapshotRootOnBoot = false;
        snapshotInterval = "hourly";
        configs = {
          adminhome = commonConfig // {
            SUBVOLUME = "/home/${username}";
          };
          adminmedia = commonConfig // {
            SUBVOLUME = "/home/${username}/media";
          };
          postgres = commonConfig // {
            SUBVOLUME = "/var/lib/postgresql";
          };
        };
      };

    # create nested .snapshots subvolumes to store the snapshots taken by snapper
    # NB: The .snapshots directory must be owned by root and must not be writable (eg. r-x) by anybody else.
    systemd.tmpfiles.rules = [
      # type path mode user group (expiry)
      "v /home/${username}/.snapshots 0750 root ${username} -"
      "v /home/${username}/media/.snapshots 0750 root ${username} -"
      "v /var/lib/postgresql/.snapshots 0750 root ${username} -"
    ];
  };
}
