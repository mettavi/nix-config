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
              type = "btrfs";
              extraArgs = [ "-f" ]; # Override existing partition
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                };
                # A nested subvolume doesn't need a mountpoint as its parent is mounted
                "@root/tmp" = {
                };
                "@root/var/cache" = {
                };
                "@nix" = {
                  mountpoint = "/nix";
                };
                "@roothome" = {
                  mountpoint = "/root";
                };
                "@roothome/.cache" = {
                };
                "@vlcontainers" = {
                  mountpoint = "/var/lib/containers";
                };
                "@libvirtimgs" = {
                  mountpoint = "/var/lib/libvirt/images";
                };
                "@vlpostgres" = {
                  mountpoint = "/var/lib/postgresql";
                };
                "@varlog" = {
                  mountpoint = "/var/log";
                };
                "@vartmp" = {
                  mountpoint = "/var/tmp";
                };
                "@home" = {
                  mountpoint = "/home";
                };
                "@adminhome" = {
                  mountpoint = "/home/${username}";
                };
                "@adminhome/.cache" = {
                };
                "@admincontainers" = {
                  mountpoint = "/home/${username}/.local/share/containers";
                  mountOptions = optionals config.mettavi.system.desktops.gnome.enable [
                    "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
                  ];
                };
                "@admindownloads" = {
                  mountpoint = "/home/${username}/Downloads";
                  mountOptions = optionals config.mettavi.system.desktops.gnome.enable [
                    "x-gvfs-hide" # hide the subvolume from the Files (Nautilus) devices menu
                    "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
                  ];
                };
                "@adminmedia" = {
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
