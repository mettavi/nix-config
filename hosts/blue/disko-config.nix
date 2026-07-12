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
    sda1 = {
      type = "disk";
      device = "/dev/sda1";
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
            # end = "-32G";
            content =
              let
                cfg = config.mettavi.system.devices.disko-btrfs;
              in
              {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                subvolumes = mapAttrs (
                  subvol: subvolCfg:
                  mkIf subvolCfg.enable {
                    mountpoint = "${subvolCfg.mountpoint}";
                    mountOptions = subvolCfg.mountOptions ++ cfg.commonMountOptions;
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
