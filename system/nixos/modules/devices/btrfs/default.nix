{
  config,
  lib,
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
  };
}
