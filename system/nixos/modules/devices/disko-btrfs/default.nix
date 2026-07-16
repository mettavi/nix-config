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
  utils,
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
  options.mettavi.system.devices.disko-btrfs = with lib.types; {
    enable = mkOption {
      type = bool;
      default = false;
      description = "Create (on initial install) and mount btrfs subvolumes with disko";
    };
    commonMountOptions = mkOption {
      type = listOf str;
      default = commonOptions ++ btrfsOptions;
      description = "Mountpoint options common to all btrfs subvolumes";
    };
    subvolumes = mkOption {
      type = attrsOf (submodule {
        options = {
          enable = mkOption {
            type = bool;
            default = true;
            description = "Enable this btrfs subvolume";
          };
          mountpoint = mkOption {
            type = nullOr path;
            default = null;
            description = "Where to mount the btrfs subvolume (null for a nested subvolume that isn't mounted separately)";
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
      default = { };
    };
  };

  config = mkMerge [
    {
      mettavi.system.devices.disko-btrfs.subvolumes = {
        "@root".mountpoint = mkDefault "/";
        "@root/tmp" = { };
        "@root/var/cache" = { };
        "@nix".mountpoint = mkDefault "/nix";
        "@roothome".mountpoint = mkDefault "/root";
        "@roothome/.cache" = { };
        "@vlcontainers".mountpoint = mkDefault "/var/lib/containers";
        "@libvirtimgs".mountpoint = mkDefault "/var/lib/libvirt/images";
        "@vlpostgres".mountpoint = mkDefault "/var/lib/postgresql";
        "@varlog".mountpoint = mkDefault "/var/log";
        "@vartmp".mountpoint = mkDefault "/var/tmp";
        "@home".mountpoint = mkDefault "/home";
        "@adminhome".mountpoint = mkDefault "/home/${username}";
        "@adminhome/.cache" = { };
        "@admincontainers" = {
          mountpoint = mkDefault "/home/${username}/.local/share/containers";
          mountOptions = mkDefault (
            optionals config.mettavi.system.desktops.gnome.enable [ "x-gvfs-trash" ]
            ++ commonOptions
            ++ btrfsOptions
          );
        };
        "@admindownloads" = {
          mountpoint = mkDefault "/home/${username}/Downloads";
          mountOptions = mkDefault (
            optionals config.mettavi.system.desktops.gnome.enable [ "x-gvfs-trash" ]
            ++ commonOptions
            ++ btrfsOptions
          );
        };
        "@adminmedia" = {
          mountpoint = mkDefault "/home/${username}/media";
          mountOptions = mkDefault (
            optionals config.mettavi.system.desktops.gnome.enable [
              "x-gvfs-hide"
              "x-gvfs-trash"
            ]
            ++ commonOptions
            ++ btrfsOptions
          );
        };
        "@swap".mountpoint = mkDefault "/.swapvol";
      };
    }
    (mkIf cfg.enable {
      fileSystems = {
        "/var/lib/postgresql" = {
          device = mkDefault "/dev/disk/by-label/nixos";
          # Ensures /var/lib is mounted first
          depends = [ "/var/lib" ];
        };
        "/home" = {
          device = mkDefault "/dev/disk/by-label/nixos";
          # required on home directories for sops-nix to work with btrfs
          # See https://github.com/Mic92/sops-nix/issues/721
          # ensure the home subvolume is mounted early for sops-nix
          neededForBoot = true;
        };
        "/home/${username}" = {
          device = mkDefault "/dev/disk/by-label/nixos";
          neededForBoot = true;
        };
      };

      ######################################################
      # SET NO COPY-ON-WRITE (NODATACOW) ON SPECIAL BTRFS SUBVOLUMES
      # NB: 1) Setting this by a mount option will apply the option to ALL subvolumes on the partition.
      #        This method (using systemd tmpfiles) allows it to be set per subvolume.
      #     2) This is best used on an empty directory as it only applies to NEW files.
      #     3) Nodatacow implies nodatasum (no data checksumming), and disables compression.

      # execute the systemd tmpfiles rules below AFTER the btrfs subvolumes have been mounted
      systemd =
        let
          nocowVols = [
            "@libvirtimgs"
            "@swap"
            "@vlpostgres"
          ];
          # resolve to mountpoints, dropping any disabled (or missing) subvolumes
          nocowPaths = lib.filter (p: p != null) (
            map (
              nocowVol:
              let
                subvol = cfg.subvolumes.${nocowVol} or null;
              in
              if subvol != null && subvol.enable then subvol.mountpoint else null
            ) nocowVols
          );

          nocowSysMounts = path: "${utils.escapeSystemdPath path}.mount";
        in
        {
          services.systemd-tmpfiles-setup = {
            requires = map nocowSysMounts nocowPaths;
            after = map nocowSysMounts nocowPaths;
          };
          # set the swap subvolume to no COW even though the swap file will be set up correctly
          # see https://github.com/nix-community/disko/issues/493 for details
          # type path mode user group (expiry) (argument)
          tmpfiles.rules = map (path: "h ${path} - - - - +C") nocowPaths;
        };
    })
  ];
}
