# NOTE: Disko is not supported on multi-boot systems.
# It is best suited to remote servers or VMs where the whole disk can be dedicated to nixos.
{ config, lib, ... }:
with lib;
{
  # NB: See https://wiki.archlinux.org/title/GPT_fdisk#Partition_type for a list of disk type codes
  # config = mkIf cfg.enable {
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
            content = {
              # passwordFile = "/tmp/secret.key";
              # settings.allowDiscards = true;
              type = "btrfs";
              extraArgs = [ "-f" ]; # Override existing partition
              subvolumes = {
                "@root" = {
                  enable = true;
                  mountpoint = "/";
                };
                # A nested subvolume doesn't need a mountpoint as its parent is mounted
                "@root/tmp" = {
                  enable = true;
                };
                "@root/var/cache" = {
                  enable = true;
                };
                "@nix" = {
                  enable = true;
                  mountpoint = "/nix";
                };
                "@roothome" = {
                  enable = true;
                  mountpoint = "/root";
                };
                "@roothome/.cache" = {
                  enable = true;
                };
                "@vlcontainers" = {
                  enable = true;
                  mountpoint = "/var/lib/containers";
                };
                "@libvirtimgs" = {
                  enable = true;
                  mountpoint = "/var/lib/libvirt/images";
                };
                "@vlpostgres" = {
                  enable = true;
                  mountpoint = "/var/lib/postgresql";
                };
                "@varlog" = {
                  enable = true;
                  mountpoint = "/var/log";
                };
                "@vartmp" = {
                  enable = true;
                  mountpoint = "/var/tmp";
                };
                "@home" = {
                  enable = true;
                  mountpoint = "/home";
                };
                "@adminhome" = {
                  enable = true;
                  mountpoint = "/home/${username}";
                };
                "@adminhome/.cache" = {
                  enable = true;
                };
                "@admincontainers" = {
                  enable = true;
                  mountpoint = "/home/${username}/.local/share/containers";
                  mountOptions = optionals config.mettavi.system.desktops.gnome.enable [
                    "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
                  ];
                };
                "@admindownloads" = {
                  enable = true;
                  mountpoint = "/home/${username}/Downloads";
                  mountOptions = optionals config.mettavi.system.desktops.gnome.enable [
                    "x-gvfs-hide" # hide the subvolume from the Files (Nautilus) devices menu
                    "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
                  ];
                };
                "@adminmedia" = {
                  enable = true;
                  mountpoint = "/home/${username}/media";
                  mountOptions = optionals config.mettavi.system.desktops.gnome.enable [
                    "x-gvfs-hide"
                    "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
                  ];
                };
              };
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
  # };
}
