{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.devices.disko;
in
{
  config = mkIf cfg.enable {
    mettavi.system.devices.disko.disks = {
      "nvme0n1" = {
        device = "/dev/nvme0n1";
        name = "nvme0n1";
        partitions = {
          "ESP" = {
            label = "EFI";
            name = "ESP";
            partType = "EF00"; # EFI System Partition
            content = {
              format = "vfat";
              mountPoint = "/efi";
              mountOptions = [
                "fmask=0022"
                "dmask=0022"
              ];
              type = "filesystem";
            };
          };
          "boot" = {
            label = "boot";
            name = "boot";
            partType = "EA00"; # XBOOTLDR partition
            content = {
              format = "vfat";
              mountPoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
              type = "filesystem";
            };
          };
          "swap" = {
            label = "swap";
            name = "swap";
            size = "8G";
            content = {
              type = "swap";
            };
          };
          "win11pro" = {
            name = "win11pro";
            content = {
              type = "ntfs";
              mountPoint = "/mnt/win11pro";
              mountOptions = [
                "nofail"
                "rw"
                "uid=1000"
                "windows_names"
              ];
            };
          };
          "nixos" = {
            label = "nixos";
            name = "nixos";
            content = {
              type = "btrfs";
              btrfsSubs = {
                "/" = {
                  mountPoint = "/";
                  subName = "@root";
                };
                "/nix" = {
                  mountPoint = "/nix";
                  subName = "@nix";
                };
                "/root" = {
                  mountPoint = "/root";
                  subName = "@roothome";
                };
                "/home" = {
                  mountPoint = "/home";
                  subName = "@home";
                };
                "home/${username}" = {
                  mountPoint = "/home/${username}";
                  subName = "@adminhome";
                };
                "home/${username}" = {
                  mountPoint = "/home/${username}/.local/share/containers";
                  subName = "@admincontainers";
                };
                "/home/${username}/Downloads" = {
                  mountPoint = "/home/${username}/Downloads";
                  subName = "@admindownloads";
                };
                "/home/${username}/Downloads" = {
                  mountPoint = "/home/${username}/Downloads";
                  mountOptions = [
                    "x-gvfs-hide"
                  ];
                  subName = "@admindownloads";
                };
                "/home/${username}/media" = {
                  mountPoint = "/home/${username}/media";
                  mountOptions = [
                    "x-gvfs-hide"
                  ];
                  subName = "@adminmedia";
                };
                "/var/lib/containers" = {
                  mountPoint = "/var/lib/containers";
                  subName = "@vlcontainers";
                };
                "/var/lib/libvirt/images" = {
                  mountPoint = "/var/lib/libvirt/images";
                  subName = "@libvirtimgs";
                };
                "/var/lib/postgresql" = {
                  mountPoint = "/var/lib/postgresql";
                  subName = "@vlpostgres";
                };
                "/var/log" = {
                  mountPoint = "/var/log";
                  subName = "@varlog";
                };
                "/var/tmp" = {
                  mountPoint = "/var/tmp";
                  subName = "@vartmp";
                };
              };
            };
          };
        };
      };
    };
  };
}
