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
      type = bool;
      default = false;
      description = "Partition and configure a host's storage devices";
    };
    disks = mkOption {
      type = attrsOf (submodule {
        options = {
          device = mkOption {
            type = str;
            description = "The device path under /dev/disk/by-param/id (or /dev/diskid)";
          };
          name = mkOption {
            type = str;
            description = "The label of the physical disk";
          };
          partScheme = mkOption {
            type = enum [
              "gpt"
              "msdos"
            ];
            description = "The disk partitioning scheme to use";
            default = "gpt";
          };
          partitions = mkOption {
            type = attrsOf (submodule {
              options = {
                commonOptions = mkOption {
                  type = listOf str;
                  default = [
                    "defaults"
                    "noatime"
                  ];
                  description = "Specify mount options common to all partitions";
                };
                label = mkOption {
                  type = str;
                  description = "Set the LABEL of the partition";
                };
                name = mkOption {
                  type = str;
                  description = "The name of the partition";
                };
                partType = mkOption {
                  type = enum [
                    "primary"
                    "logical"
                    "extended"
                  ];
                  description = "The global partition type";
                  default = "primary";
                };
                content = mkOption {
                  type = attrsOf (submodule {
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
                      mountPoint = mkOption {
                        type = str;
                        description = "Define the mount point for the subvolume";
                      };
                      mountOptions = mkOption {
                        type = listOf str;
                        description = "Define any mount options specific to the mount point";
                      };
                      name = mkOption {
                        type = str;
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
                        type = listOf str;
                        default = [ "compress=zstd" ];
                        description = "Specify mount options common to all btrfs subvolumes";
                      };
                      btrfsSubs = mkOption {
                        type = attrsOf (submodule {
                          options = {
                            mountPoint = mkOption {
                              type = str;
                              description = "Define the mount point for the subvolume";
                            };
                            mountOptions = mkOption {
                              type = listOf str;
                              description = "Define any mount options specific to the mount point";
                            };
                            subName = mkOption {
                              type = str;
                              description = "The btrfs subvolume name";
                            };
                          };
                        });
                      };
                    };
                  });
                };
              };
            });
          };
        };
      });
    };
  };
  config = mkIf cfg.enable {
    disko.devices.disk = mapAttrs (
      disk: diskCfg: {
        "${diskCfg.name}" = {
          type = "disk";
          device = "${diskCfg.device}";
          content = {
            type = "${diskCfg.partScheme}";
            partitions = mapAttrs (part: partCfg: {
              "${partCfg.name}" = {
                label = optionalString (cfg.disks.name.partitions.name.label != "") "${partCfg.label}";
                name = "${partCfg.name}";
                size = optionalString (cfg.disks.name.partitions.name.size != "") "${partCfg.size}";
                type = optionalString (cfg.disks.name.partitions.name.partType != "") "${partCfg.partType}";
                content = mapAttrs (content: contentCfg: {
                  type = optionalString (cfg.disks.name.partitions.name.content.type != "") "${contentCfg.type}";
                  extraArgs = optionals (cfg.disks.name.partitions.name.content.type != "") "${contentCfg.extraArgs}";
                  format =
                    optionalString (cfg.disks.name.partitions.name.content.format != "")
                      "${contentCfg.format}";
                  mountpoint = optionalString (
                    cfg.disks.name.partitions.name.content.mountPoint != ""
                  ) "${contentCfg.mountPoint}";
                  mountOptions =
                    optionals (cfg.disks.name.partitions.name.content.mountOptions != "") "${partCfg.commonOptions}"
                    ++ "${contentCfg.mountOptions}";
                  subvolumes = mapAttrs (
                    subvol: subvolCfg:
                    mkIf (cfg.disks.name.partitions.name.content.btrfsSubs != "") {
                      "${subvolCfg.subName}" = {
                        mountpoint = "${subvolCfg.mountPoint}";
                        mountOptions = "${contentCfg.commonBtrfsOptions}" ++ "${subvolCfg.mountOptions}";
                      };
                    }
                  ) cfg.disks.partitions.name.content.btrfsSubs;
                }) cfg.disks.name.partitions.name.content;
              };
            }) cfg.disks.name.partitions;
          };
        };
      }
    );
  };
}
