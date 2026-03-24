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
  mounts = [
    {
      enable = true;
      datadir = "/home/${username}";
      snapsvol = "@adminhome-snaps";
    }
    {
      enable = true;
      datadir = "/home/${username}/media";
      snapsvol = "@adminmedia-snaps";
    }
    {
      enable = false;
      datadir = "/var/lib/postgresql";
      snapsvol = "@vlpgsql-snaps";
    }
  ];
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
    environment.systemPackages = with pkgs; [
      btrfs-assistant # btrfs gui management tool
    ];

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
          # this allows the user to run snapper commands
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
          TIMELINE_CLEANUP = true;
          # Hourly/daily/weekly/monthly/yearly snapshots are the first snapshot taken in that time period
          # Keep snapshots for the last x hours/days/weeks/months/years
          TIMELINE_MIN_AGE = "1800"; # keep snapshots for at least 30 mins
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
          vlpgsql = commonConfig // {
            SUBVOLUME = "/var/lib/postgresql";
          };
        };
      };

    # create services to create btrfs subvolumes and directories before they are mounted
    systemd.services = builtins.listToAttrs (
      map (
        mount:
        let
          mountParent = [
            (builtins.substring 1 (-1) (builtins.replaceStrings [ "/" ] [ "-" ] "${mount.datadir}") + ".mount")
          ];
          mountUnit = [
            # -1 takes the rest of the string
            (builtins.substring 1 (-1) (
              builtins.replaceStrings [ "/" ] [ "-" ] "${mount.datadir}" + "-.snapshots.mount"
            ))
          ];
          serviceUnit = (builtins.substring 1 (-1) "${mount.snapsvol}");
        in
        # mkIf mount.enable {
        {
          name = serviceUnit;
          value = {
            description = "Ensure the subvolume ${mount.snapsvol} and directory ${mount.datadir}/.snapshots are created before they need to be mounted";
            path = with pkgs; [
              btrfs-progs
              coreutils
              gnugrep
              util-linux # for the mount binary
            ];
            # create the subvolumes and directories BEFORE they are to be mounted
            before = mountUnit;
            requiredBy = mountUnit;
            restartIfChanged = false;
            script = ''
              # create TOP-LEVEL .snapshots btrfs subvolumes to store the snapshots taken by snapper
              # see https://www.reddit.com/r/btrfs/comments/kkms59/snappers_snapshot_location/
              # and https://www.reddit.com/r/btrfs/comments/rnl6j5/is_there_any_compelling_reason_to_not_use_nested/
              # and https://bbs.archlinux.org/viewtopic.php?id=194491
              # also create the corresponding directories to be mounted on them
              # NB: For snapper, the .snapshots directory must be owned by root and must not be writable (eg. r-x) by anybody else.
              # see https://discourse.nixos.org/t/snapper-should-snapshots-subvolumes-be-created-automatically/22329/11

              # Check if the btrfs subvolume exists
              if ! btrfs subvolume list / | grep -q ${mount.snapsvol}; then
                mount /dev/disk/by-label/nixos /mnt/btrfs
                # Create the subvolume
                btrfs subvolume create /mnt/btrfs/${mount.snapsvol}
                echo "Subvolume created at ${mount.snapsvol}"
                chown root:${username} /mnt/btrfs/${mount.snapsvol}
                chmod 750 /mnt/btrfs/${mount.snapsvol}
                umount /mnt/btrfs
              else
                echo "Subvolume already exists at ${mount.snapsvol}"
              fi

              # Check if the directory exists
              if [ ! -d "${mount.datadir}/.snapshots" ]; then
                # Create the directory
                echo "Folder ${mount.datadir}/.snapshots does not exist. Creating it..."
                mkdir -p "${mount.datadir}/.snapshots" 
                chown root:${username} "${mount.datadir}/.snapshots" 
                chmod 750 "${mount.datadir}/.snapshots" 
              else
                echo "Folder ${mount.datadir}/.snapshots already exists."
              fi 
            '';
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = "yes";
            };
            unitConfig = {
              # disable the defaults to prevent circular dependency errors
              DefaultDependencies = "no";
              # only run after the parent directories have been mounted
              RequiresMountsFor = [ mountParent ];
            };
            wantedBy = [
              "local-fs.target"
            ];
          };
        }
      ) mounts
    );

    # mount the subvolumes on the .snaphosts directories
    fileSystems = builtins.listToAttrs (
      map (
        mount:
        # mkIf mount.enable {
        {
          name = mount.datadir + "/.snapshots";
          value = {
            device = mkForce "/dev/disk/by-label/nixos";
            fsType = "btrfs";
            options = [
              "nofail"
              "defaults"
              "discard"
              "noatime"
              "compress=zstd"
              "subvol=${mount.snapsvol}"
            ];
          };
        }) mounts
    );
  };
}
