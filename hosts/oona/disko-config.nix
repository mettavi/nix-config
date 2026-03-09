{
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

          win11pro = {
            label = "w11pro";
            name = "win11pro";
            type = "ntfs";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/mnt/win11pro";
              mountOptions = [
                "nofail"
                "rw"
                "uid=1000"
                "windows_names"
              ];
            };
          };

          nixos = {
            end = "-32G";
            content = {
              name = "nixos";
              passwordFile = "/tmp/secret.key";
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@roothome" = {
                    mountpoint = "/root";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@vlcontainers" = {
                    mountpoint = "/var/lib/containers";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@libvirtimgs" = {
                    mountpoint = "/var/lib/libvirt/images";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@vlpostgres" = {
                    mountpoint = "/var/lib/postgresql";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@varlog" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@vartmp" = {
                    mountpoint = "/var/tmp";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@adminhome" = {
                    mountpoint = "/home/timotheos";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@admincontainers" = {
                    mountpoint = "/home/timotheos/.local/share/containers";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@admindownloads" = {
                    mountpoint = "/home/timotheos/Downloads";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@adminmedia" = {
                    mountpoint = "/home/timotheos/media";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
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
  };
}
