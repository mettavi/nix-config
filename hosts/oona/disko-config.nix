# NOTE: Disko is not supported on multi-boot systems.
# It is best suited to remote servers or VMs where the whole disk can be dedicated to nixos.
{ config, lib, ... }:
with lib;
let
  cfg = config.mettavi.system.devices.disko;
in
{
  options.mettavi.system.devices.disko = {
    enable = mkEnableOption "Use disko to set up and configure this host";
  };

  # NB: See https://wiki.archlinux.org/title/GPT_fdisk#Partition_type for a list of disk type codes
  config = mkIf cfg.enable {
    disko.devices.disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
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
            nix-boot = {
              label = "EFI";
              name = "nix-boot";
              size = "1024M";
              type = "EA00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            cachyos = {
              label = "cachyos";
              name = "cachyos";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/mnt/cachyos";
                mountOptions = [
                  "nofail"
                  "compress=zstd"
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
                  extraArgs = [ "-f" ];
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
