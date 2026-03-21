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
      description = "Create and configure a btrfs partition using disko";
    };
    commonMountOptions = mkOption {
      type = listOf str;
      default = [ "compression=zstd" ];
      description = "Mountpoint options common to all subvolumes";
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
            label = mkOption {
              type = str;
              description = "The name of the btrfs subvolume";
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
    };
  };

  config = mkIf cfg.enable {
    # CHECK BTRFS FILE CONSISTENCY
    # check the status of the last scrub with "btrfs scrub status /" or in the journal
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };

    # configure default btrfs subvolumes
    mettavi.system.devices.disko-btrfs.subvolumes = {
      "@root" = {
        enable = mkDefault true;
        label = "@root";
        mountpoint = "/";
      };
      # A nested subvolume doesn't need a mountpoint as its parent is mounted
      "@root/tmp" = {
        enable = mkDefault true;
      };
      "@root/var/cache" = {
        enable = mkDefault true;
      };
      "@nix" = {
        enable = mkDefault true;
        label = "@nix";
        mountpoint = "/nix";
      };
      "@roothome" = {
        enable = mkDefault true;
        label = "@roothome";
        mountpoint = "/root";
      };
      "@roothome/.cache" = {
        enable = mkDefault true;
      };
      "@vlcontainers" = {
        enable = mkDefault true;
        label = "@vlcontainers";
        mountpoint = "/var/lib/containers";
      };
      "@libvirtimgs" = {
        enable = mkDefault true;
        label = "@libvirtimgs";
        mountpoint = "/var/lib/libvirt/images";
      };
      "@vlpostgres" = {
        enable = mkDefault true;
        label = "@vlpostgres";
        mountpoint = "/var/lib/postgresql";
      };
      "@varlog" = {
        enable = mkDefault true;
        label = "@varlog";
        mountpoint = "/var/log";
      };
      "@vartmp" = {
        enable = mkDefault true;
        label = "@vartmp";
        mountpoint = "/var/tmp";
      };
      "@home" = {
        enable = mkDefault true;
        label = "@home";
        mountpoint = "/home";
      };
      "@adminhome" = {
        enable = mkDefault true;
        label = "@adminhome";
        mountpoint = "/home/${username}";
      };
      "@adminhome/.cache" = {
        enable = mkDefault true;
      };
      "@admincontainers" = {
        enable = mkDefault true;
        label = "@admincontainers";
        mountpoint = "/home/${username}/.local/share/containers";
        mountOptions = [
          "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
        ];
      };
      "@admindownloads" = {
        enable = mkDefault true;
        label = "@admindownloads";
        mountpoint = "/home/${username}/Downloads";
        mountOptions = [
          "x-gvfs-hide" # hide the subvolume from the Files (Nautilus) devices menu
          "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
        ];
      };
      "@adminmedia" = {
        enable = mkDefault true;
        label = "@adminmedia";
        mountpoint = "/home/${username}/media";
        mountOptions = [
          "x-gvfs-hide"
          "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
        ];
      };
    };
    fileSystems = {
      "/var/lib/postgresql" = {
        device = "/dev/disk/by-label/nixos";
        # Ensures /var/lib is mounted first
        depends = [ "/var/lib" ];
      };
      # ensure the home subvolume is mounted early for sops-nix
      "/home" = {
        device = "/dev/disk/by-label/nixos";
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
    # SET NO COPY-ON-WRITE ON SPECIAL BTRFS SUBVOLUMES
    # NB: 1) Setting this by a mount option will apply the option to ALL subvolumes on the partition.
    #        This method (using systemd tmpfiles) allows it to be set per subvolume.
    #     2) This is best used on an empty directory as it only applies to NEW files.
    #     3) Disabling COW will also disable btrfs file integrity checksumming.

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
