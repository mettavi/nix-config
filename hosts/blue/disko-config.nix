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
            label = "EFI";
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
                mountpoint = "/";
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
          swap = {
            size = "8G";
            content = {
              type = "swap";
              randomEncryption = true;
              resumeDevice = true;
            };
          };
        };
      };
    };
  };
}
