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
  pkgs,
  username,
  ...
}:
with lib;
let
  btrfsOptions = [ "compress=zstd" ];
  commonOptions = [
    "defaults"
    "discard"
    "noatime"
  ];
  mountUnits = [
    "-.mount"
    "nix.mount"
    "root.mount"
    "var-lib-containers.mount"
    "var-lib-libvirt-images.mount"
    "var-lib-postgresql.mount"
    "var-log.mount"
    "var-tmp.mount"
    "home.mount"
    "home-${username}.mount"
    "home-${username}-.local-share-containers.mount"
    "home-${username}-Downloads.mount"
    "home-${username}-media.mount"
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
        "@libvirtimgs" = {
          enable = true;
          mountpoint = "/var/lib/libvirt/images";
          mountOptions = commonOptions;
        };
        "@vlpostgres" = {
          enable = true;
          mountpoint = "/var/lib/postgresql";
          mountOptions = commonOptions;
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

    # WARNING: Do NOT make important systemd directories immutable,
    # otherwise the system will not be able to boot!

    # MAKE UNDERLYING DIRECTORIES IMMUTABLE
    systemd = {
      services."pre-btrfs-mount" = {
        # DISABLE THIS SERVICE, UNTIL A SAFE ALTERNATIVE IS FOUND
        enable = false;
        description = "Set immutable attribute on mount point";
        # ensure this is set BEFORE the btrfs subvolume is mounted
        before = mountUnits;
        requiredBy = mountUnits;
        path = with pkgs; [
          e2fsprogs # contains the chattr binary
        ];
        script = ''
          # see https://serverfault.com/a/570271
          chattr +i / /nix /root /home \
          /var/lib/containers /var/lib/libvirt/images /var/lib/postgresql /var/log /var/tmp \ 
          /home/${username} /home/${username}/.local/share/containers /home/${username}/Downloads /home/${username}/media
        '';
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
        };
        unitConfig = {
          DefaultDependencies = false;
        };
        wantedBy = [ "multi-user.target" ];
      };
      # DISABLE THESE MOUNT UNITS, UNTIL A SAFE ALTERNATIVE IS FOUND
      # ensure all btrfs subvolumes are mounted AFTER the chattr service (see above)
      #   mounts = map (munit: {
      #     after = [ "pre-btrfs-mount.service" ];
      #     requires = [ "pre-btrfs-mount.service" ];
      #     where = builtins.replaceStrings [ "//" ] [ "/" ] (
      #       "/" + builtins.replaceStrings [ "-" ".mount" ] [ "/" "" ] "${munit}"
      #     );
      #     what = "/dev/disk/by-label/nixos";
      #   }) mountUnits;
    };

    ######################################################
    # SET NO COPY-ON-WRITE (NODATACOW) ON SPECIAL BTRFS SUBVOLUMES
    # NB: 1) Setting this by a mount option will apply the option to ALL subvolumes on the partition.
    #        This method (using systemd tmpfiles) allows it to be set per subvolume.
    #     2) This is best used on an empty directory as it only applies to NEW files.
    #     3) Nodatacow implies nodatasum (no data checksumming), and disables compression.

    systemd.tmpfiles.rules = [
      # type path mode user group (expiry) (argument)
      "h /var/lib/libvirt/images - - - - +C"
      "h /var/lib/postgresql - - - - +C"
    ];

    # make it certain that the above systemd tmpfiles rules are executed
    # AFTER the btrfs subvolumes have been mounted
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
