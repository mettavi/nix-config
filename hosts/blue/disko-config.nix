# NOTE: Disko is not supported on multi-boot systems.
# It is best suited to remote servers or VMs where the whole disk can be dedicated to nixos.
{ lib, ... }:
with lib;
{
  mettavi.system.devices.disko-btrfs.subvolumes = {
    # not currently running VMs on host blue
    "@libvirtimgs".enable = false;
  };

  disko.devices.disk = {
    sda = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            # a value between 0 and 32767. Higher numbers indicate higher priority.
            # null lets the kernel choose a priority, which will show up as a negative value.
            priority = 1;
            # The UUID (also known as GUID) of the PARTITION. Note that this is distinct from the UUID of the filesystem.
            # You can generate a UUID with the command `uuidgen -r`.
            uuid = "ca8cf1b5-61e9-43b0-8402-acf1edb1bcfd";
            name = "ESP";
            start = "1M";
            end = "1024M";
            # NB: See https://wiki.archlinux.org/title/GPT_fdisk#Partition_type
            # for a list of disk type codes
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "umask=0077"
              ];
            };
          };
          nixos = {
            size = "100%";
            content =
              let
                cfg = config.mettavi.system.devices.disko-btrfs;
              in
              {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # A path to mount the BTRFS filesystem to
                mountpoint = "/";
                # A list of options to pass to mount
                mountOptions = [ "defaults" ];
                # Subvolumes to define for BTRFS
                subvolumes = mapAttrs (
                  subvol: subvolCfg:
                  mkIf subvolCfg.enable {
                    mountpoint = "${subvolCfg.mountpoint}";
                    mountOptions = subvolCfg.mountOptions ++ cfg.commonMountOptions;
                  }
                  // {
                    # Subvolume for the swapfile
                    "@swap" = {
                      mountpoint = "/swap";
                      mountOptions = [
                        "defaults"
                        "noatime"
                      ];
                      # although it is possible to set up the swapfile on the root subvolume,
                      # it is recommended to create a dedicated subvolume for it
                      swap = {
                        # Size of the swap file (e.g. 2G)
                        swapfile = {
                          size = "4G";
                          # Path to the swap file (relative to the mountpoint, defaults to the attribute name)
                          # path = "swapfile";
                        };
                      };
                    };
                  }
                ) cfg.subvolumes;
              };
          };
        };
      };
    };
  };
}
