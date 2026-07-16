# NOTE: Disko is not supported on multi-boot systems.
# It is best suited to remote servers or VMs where the whole disk can be dedicated to nixos.
{ config, lib, ... }:
with lib;
{
  # select which btrfs subvols to exclude from the defaults set in the disko-btrfs module
  # not currently running VMs on host blue
  mettavi.system.devices.disko-btrfs.subvolumes."@libvirtimgs".enable = false;

  disko.devices.disk = {
    sda = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            # Priority of the partition, smaller values are created first
            # Attempt to boot from this partition first
            priority = 1;
            # The UUID (also known as GUID) of the PARTITION. Note that this is distinct from the UUID of the filesystem.
            # You can generate a UUID with the command `uuidgen -r`.
            uuid = "6feb6d11-47b2-400e-927f-a6c4e1089101";
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
            uuid = "d679c570-aded-494f-8090-b3c465ddaad8";
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
                subvolumes =
                  (mapAttrs (
                    subvol: subvolCfg:
                    {
                      mountOptions = subvolCfg.mountOptions ++ cfg.commonMountOptions;
                    }
                    // lib.optionalAttrs (subvolCfg.mountpoint != null) { mountpoint = subvolCfg.mountpoint; }
                  ) (lib.filterAttrs (subvol: subvolCfg: subvolCfg.enable) cfg.subvolumes))
                  // {
                    # Subvolume for the swapfile
                    "@swap" = {
                      mountpoint = cfg.subvolumes."@swap".mountpoint;
                      mountOptions = [
                        "defaults"
                        "noatime"
                      ];
                      swap = {
                        swapfile = {
                          size = "4G";
                        };
                      };
                    };
                  };
              };
          };
        };
      };
    };
  };
}
