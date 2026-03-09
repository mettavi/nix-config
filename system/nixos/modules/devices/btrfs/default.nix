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
