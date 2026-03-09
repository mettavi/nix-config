{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.devices.btrfs;
in
{
  options.mettavi.system.devices.btrfs = {
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
    subvolumes =
      with lib.types;
      attrsOf (submodule {
        options = {
          enable = mkEnableOption "Enable this btrfs subvolume";
          label = mkOption {
            type = str;
            description = "The name of the btrfs subvolume";
          };
          mountpoint = mkOption {
            type = str;
            description = "Where to mount the btrfs subvolume";
          };
          mountOptions = mkOption {
            type = listOf str;
            description = "Mount options specific to a subvolume";
          };
        };
      });
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
    cfg.subvolumes = {
      "@root" = {
        enable = mkDefault true;
        label = "@root";
        mountpoint = "/";
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
      "@adminhome" = {
        enable = mkDefault true;
        label = "@adminhome";
        mountpoint = "/home/${username}";
      };
      "@admincontainers" = {
        enable = mkDefault true;
        label = "@admincontainers";
        mountpoint = "/home/${username}/.local/share/containers";
      };
      "@admindownloads" = {
        enable = mkDefault true;
        label = "@admindownloads";
        mountpoint = "/home/${username}/Downloads";
        # hide in the Nautilus devices menu
        mountOptions = [ "x-gvfs-hide" ];
      };
      "@adminmedia" = {
        enable = mkDefault true;
        label = "@adminmedia";
        mountpoint = "/home/${username}/media";
        mountOptions = [ "x-gvfs-hide" ];
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
  };
}
