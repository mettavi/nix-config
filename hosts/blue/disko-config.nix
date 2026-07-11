# NOTE: Disko is not supported on multi-boot systems.
# It is best suited to remote servers or VMs where the whole disk can be dedicated to nixos.
{ config, lib, ... }:
with lib;
{
  # NB: See https://wiki.archlinux.org/title/GPT_fdisk#Partition_type for a list of disk type codes
  config = mkIf cfg.enable {
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
              size = "200M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
                mountOptions = [
                  "fmask=0022"
                  "dmask=0022"
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
                  # passwordFile = "/tmp/secret.key";
                  # settings.allowDiscards = true;
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
  };
}
