################ BTRFS SUBVOLUMES ###################
# To make a new TOP-LEVEL btrfs subvolume, mount the hidden root subvolume first:
# eg. sudo mount /dev/nvme0n1p7 /mnt/btrfs && sudo btrfs subvolume create @subvolname
# To easily make a NESTED btrfs subvolume, use the SAME NAME (without an @) as the existing directory:
# eg. mv /var/cache /var/cache.bak && sudo btrfs subvolume create /var/cache
# && cp -a --reflink=always /var/cache.bak/. /var/cache/
# Such nested subvolumes inherit the settings of their parents and do not need to be added to /etc/fstab
# NB: systemd (eg. /var/lib/portables and /var/lib/machines) and the os installer/other programs
# (eg. /tmp, /var/tmp, /srv) may also auto-create nested btrfs subvolumes
#####################################################
{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  btrfsOptions = [ "compress=zstd" ];
  commonOptions = [
    "defaults"
    "noatime"
  ];
  cfg = config.mettavi.system.devices.disko-btrfs;
in
{
  options.mettavi.system.devices.disko-btrfs = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Create (on initial install) and mount btrfs subvolumes with disko";
    };
    commonMountOptions = mkOption {
      type = listOf str;
      default = commonOptions ++ btrfsOptions;
      description = "Mountpoint options common to all btrfs subvolumes";
    };
    subvolumes = mkOption {
      type =
        with lib.types;
        attrsOf (submodule {
          options = {
            enable = mkOption {
              type = bool;
              default = true;
              description = "Enable this btrfs subvolume";
            };
            mountpoint = mkOption {
              type = path;
              description = "Where to mount the btrfs subvolume";
            };
            mountOptions = mkOption {
              type = listOf str;
              default = [ ];
              # Most btrfs mount options apply to the whole filesystem and only options
              # in the first mounted subvolume will take effect
              # The exception is options that are handled by the VFS layer
              # such as noatime/relatime/…, nodev, nosuid, ro, rw, dirsync
              # See https://btrfs.readthedocs.io/en/latest/ch-subvolume-intro.html#mount-options for details
              description = "Mount options specific to a subvolume";
            };
          };
        });
      default = {
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
        # the nodatacow attribute (see below) will disable zstd compression
        # on special subvolumes such as @libvirtimgs and @vlpostgres
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
          mountOptions =
            optionals (config.mettavi.system.desktops.gnome.enable) [
              "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
            ]
            ++ commonOptions
            ++ btrfsOptions;
        };
        "@admindownloads" = {
          enable = true;
          mountpoint = "/home/${username}/Downloads";
          mountOptions =
            optionals (config.mettavi.system.desktops.gnome.enable) [
              "x-gvfs-trash"
            ]
            ++ commonOptions
            ++ btrfsOptions;
        };
        "@adminmedia" = {
          enable = true;
          mountpoint = "/home/${username}/media";
          mountOptions =
            optionals (config.mettavi.system.desktops.gnome.enable) [
              "x-gvfs-hide" # hide the subvolume from the Files (Nautilus) devices menu
              "x-gvfs-trash"
            ]
            ++ commonOptions
            ++ btrfsOptions;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    fileSystems = {
      "/var/lib/postgresql" = {
        device = "/dev/disk/by-label/nixos";
        # Ensures /var/lib is mounted first
        depends = [ "/var/lib" ];
      };
      "/home" = {
        device = "/dev/disk/by-label/nixos";
        # required on home directories for sops-nix to work with btrfs
        # See https://github.com/Mic92/sops-nix/issues/721
        # ensure the home subvolume is mounted early for sops-nix
        neededForBoot = true;
      };
      "/home/${username}" = {
        device = "/dev/disk/by-label/nixos";
        neededForBoot = true;
      };
    };

    ######################################################
    # SET NO COPY-ON-WRITE (NODATACOW) ON SPECIAL BTRFS SUBVOLUMES
    # NB: 1) Setting this by a mount option will apply the option to ALL subvolumes on the partition.
    #        This method (using systemd tmpfiles) allows it to be set per subvolume.
    #     2) This is best used on an empty directory as it only applies to NEW files.
    #     3) Nodatacow implies nodatasum (no data checksumming), and disables compression.

    systemd.tmpfiles.rules =
      let
        # set the swap subvolume to no COW even though the swap file will be set up correctly
        # see https://github.com/nix-community/disko/issues/493 for details
        nocowVols = [
          "@libvirtimgs"
          "@swap"
          "@vlpostgres"
        ];
        nocowPaths =
          let
            subvol = cfg.subvolumes."${nocowVol}";
          in
          map (nocowVol: if subvol.enable then subvol.mountpoint else [ ]) nocowVols;
        # type path mode user group (expiry) (argument)
        nocowRules = path: "h ${path} - - - - +C";
      in
      lib.lists.forEach nocowPaths nocowRules;

    # systemd.tmpfiles.rules = [
    #   # type path mode user group (expiry) (argument)
    #   "h /var/lib/libvirt/images - - - - +C"
    #   "h /var/lib/postgresql - - - - +C"
    #   "h /swap/swapfile - - - - +C"
    # ];

    # execute the systemd tmpfiles rules abover AFTER the btrfs subvolumes have been mounted
    systemd.services.systemd-tmpfiles-setup = {
      requires = [
        "var-lib-libvirt-images.mount"
        "var-lib-postgresql.mount"
      ];
      after = [
        "var-lib-libvirt-images.mount"
        "var-lib-postgresql.mount"
      ];
    };
  };
}
