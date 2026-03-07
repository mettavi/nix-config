{
  config,
  lib,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.mettavi.system.devices.disko;
in
{
  options.mettavi.system.devices.disko = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Partition and configure a host's storage devices";
    };
    disks = mkOption {
      type = types.listOf (
        types.submodule {
          device = mkOption {
            type = types.str;
            description = "The device path under /dev/disk/by-param/id (or /dev/diskid)";
          };
          name = mkOption {
            type = types.str;
            description = "The label of the physical disk";
          };
          partScheme = mkOption {
            type = str;
            description = "The disk partitioning scheme to use";
            default = "gpt";
          };
          partitions = mkOption {
            type = types.listOf (
              types.submodule {
                commonOptions = mkOption {
                  type = types.listOf types.str;
                  default = [
                    "defaults"
                    "noatime"
                  ];
                  description = "Specify mount options common to all partitions";
                };
                label = mkOption {
                  type = types.str;
                  description = "Define the partition label";
                };
                name = mkOption {
                  type = str;
                  description = "The name of the partition";
                };
                partType = mkOption {
                  type = types.str;
                  description = "The global partition type";
                };
                uuid = mkOption {
                  type = types.str;
                  description = "Define the /dev/disk/by-uuid/ of the device";
                };
                content = mkOption {
                  type = types.listOf (
                    types.submodule {
                      options = {
                        size = mkOption {
                          type = str;
                          description = "The size of the partition (eg. 512M or 100%)";
                        };
                        start = mkOption {
                          type = str;
                          description = "Where to start the partition on disk";
                        };
                        end = mkOption {
                          type = str;
                          description = "Where to end the partition on disk";
                        };
                        format = mkOption {
                          type = str;
                          description = "The partition format (eg. vfat, ext4)";
                        };
                        mountPoint = lib.mkOption {
                          type = types.str;
                          description = "Define the mount point for the subvolume";
                        };
                        mountOptions = lib.mkOption {
                          type = types.listOf types.str;
                          description = "Define any mount options specific to the mount point";
                        };
                        name = lib.mkOption {
                          type = types.str;
                          description = "Define the name of the subvolume";
                        };
                        type = mkOption {
                          type = str;
                          description = "The content block partition type";
                        };
                        btrfsExtraArgs = mkOption {
                          type = listOf str;
                          description = "Define additional arguments for a btrfs content block";
                          default = [ "-f" ];
                        };
                        commonBtrfsOptions = mkOption {
                          type = types.listOf types.str;
                          default = [ "compress=zstd" ];
                          description = "Specify mount options common to all btrfs subvolumes";
                        };
                        btrfsSubs = mkOption {
                          type = listOf (
                            types.submodule {
                              mountPoint = lib.mkOption {
                                type = types.str;
                                description = "Define the mount point for the subvolume";
                              };
                              mountOptions = lib.mkOption {
                                type = types.listOf types.str;
                                description = "Define any mount options specific to the mount point";
                              };
                              subName = mkOption {
                                type = str;
                                description = "The btrfs subvolume name";
                              };
                            }
                          );
                        };
                      };
                    }
                  );
                };
              }
            );
          };
        }
      );
    };
  };

  config = mkIf cfg.enable {
    # CHECK BTRFS FILE CONSISTENCY
    # check the status of the last scrub with "btrfs scrub status /" or in the journal
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };
  };
}
