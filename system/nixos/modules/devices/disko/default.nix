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
            description = "The device path (eg. /dev/nvme0n1)";
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
                  type = str;
                  # See https://wiki.archlinux.org/title/GPT_fdisk#Partition_type for a list
                  # useful for less common and boot partition types
                  description = "The type that is set above the partition's content block";
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
                        description = "The type that is set within the partition's content block";
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
        type = "disk";
        device = "${diskCfg.device}";
        content = {
          type = "${diskCfg.partScheme}";
          partitions = mapAttrs (part: partCfg: {
            label = optionalString (cfg.disks.name.partitions.name.label != "") "${partCfg.label}";
            name = "${partCfg.name}";
            size = optionalString (cfg.disks.name.partitions.name.size != "") "${partCfg.size}";
            type = optionalString (cfg.disks.name.partitions.name.partType != "") "${partCfg.partType}";
            content =
              let
                partContent = cfg.disks.name.partitions.name.content;
              in
              {
                type = optionalString (partContent.type != "") "${partContent.type}";
                extraArgs = optionals (partContent.extraArgs != "") "${partContent.extraArgs}";
                format = optionalString (partContent.format != "") "${partContent.format}";
                mountpoint = optionalString (partContent.mountPoint != "") "${partContent.mountPoint}";
                mountOptions =
                  optionals (
                    partContent.mountOptions != "" || partContent.commonOptions != ""
                  ) "${partContent.commonOptions}"
                  ++ "${partContent.mountOptions}";
                subvolumes = mapAttrs (
                  subvol: subvolCfg:
                  mkIf (cfg.disks.name.partitions.name.content.btrfsSubs != "") {
                    mountpoint = "${subvolCfg.mountPoint}";
                    mountOptions = "${contentCfg.commonBtrfsOptions}" ++ "${subvolCfg.mountOptions}";
                  }
                ) cfg.disks.partitions.name.content.btrfsSubs;
              };
          }) cfg.disks.name.partitions;
        };
      }
    );
  };
}
