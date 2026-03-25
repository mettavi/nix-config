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

  # SHARED SETTINGS FOR EVERY SNAPPER CONFIGURATION
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

  # Helper to turn a path like /home/user into home-user (used for systemd units)
  toUnitName = path: substring 1 (-1) (replaceStrings [ "/" ] [ "-" ] path);

in
{

  # add a systemd health-check and a desktop notification service
  imports = [ ./health-check.nix ];

  options.mettavi.system.services.snapper = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure automatic btrfs snapshots using snapper";
    };
    # This allows you to pass your subvolume data into the module
    mounts = mkOption {
      description = "Attribute set of subvolumes to manage with Snapper";
      default = { };
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to enable snapshots for this subvolume";
            };
            datadir = mkOption {
              type = types.path;
              description = "The path to the directory being snapshotted (e.g. /home/user)";
            };
            snapsvol = mkOption {
              type = types.str;
              description = "The name of the Btrfs subvolume for snapshots (e.g. @home-snaps)";
            };
            extraConfig = mkOption {
              type = types.attrs;
              default = { };
              description = "Extra Snapper config options to override the defaults";
            };
          };
        }
      );
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      btrfs-assistant # btrfs gui management tool
    ];

    services.snapper = {
      cleanupInterval = "1d";
      # a list of files that should never be reverted (eg. state info like /etc/mtab)
      # Note that filters do not exclude files or directories from being snapshotted.
      # For that, use subvolumes or mount points.
      filters = "";
      # trigger the snapshot immediately if the last trigger was missed
      persistentTimer = true;
      snapshotRootOnBoot = false;
      snapshotInterval = "hourly";
      # mapAttrs handles the key-value pairing automatically
      configs = mapAttrs (
        name: mount: commonConfig // mount.extraConfig // { SUBVOLUME = mount.datadir; }
      ) enabledMounts;
    };

    # create services to create btrfs subvolumes and directories before they are mounted
    # We use mapAttrs' (the "prime" version) because we want to change the
    # key from the internal name (e.g. 'adminhome') to the snapsvol name.
    systemd.services = mapAttrs' (
      name: mount:
      let
        serviceName = "setup-snapper-${name}";
        mountUnit = "${toUnitName mount.datadir}-.snapshots.mount";
      in
      nameValuePair serviceName {
        description = "Ensure the subvolume ${mount.snapsvol} and directory ${mount.datadir}/.snapshots are created before they need to be mounted";
        path = with pkgs; [
          btrfs-progs
          coreutils
          gnugrep
          util-linux # for the mount binary
        ];
        # create the subvolumes and directories BEFORE they are to be mounted
        before = [ mountUnit ];
        requiredBy = [ mountUnit ];
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
            if [ ! -d "/mnt/btrfs" ]; then
              echo "Folder /mnt/btrfs does not exist. Creating it..."
              mkdir -p /mnt/btrfs
            else
              echo "Folder /mnt/btrfs already exists"
            fi
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
          RemainAfterExit = true;
        };
        unitConfig = {
          # disable the defaults to prevent circular dependency errors
          DefaultDependencies = false;
          # only run after the parent directories have been mounted
          RequiresMountsFor = [ "/run/systemd/generator/${toUnitName mount.datadir}.mount" ];
        };
        wantedBy = [
          # set it up during the file mounting stage of system boot
          "local-fs.target"
        ];
      }
    ) enabledMounts;

    # mount the subvolumes on the .snaphosts directories
    # mapAttrs' is great here too to set the mount point as the key
    fileSystems = mapAttrs' (
      name: mount:
      nameValuePair "${mount.datadir}/.snapshots" {
        device = "/dev/disk/by-label/nixos";
        fsType = "btrfs";
        options = [
          "nofail"
          "defaults"
          "discard"
          "noatime"
          "compress=zstd"
          "subvol=${mount.snapsvol}"
        ];
      }
    ) enabledMounts;
  };
}
