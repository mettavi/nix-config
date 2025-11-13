{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.devices.applesmc-next;
  applesmc-next = config.boot.kernelPackages.callPackage ./bld_asmcn.nix { };
in
{
  options.mettavi.system.devices.applesmc-next = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure battery thresholds for apple intel macOS devices";
    };
  };

  config = mkIf cfg.enable {
    boot.extraModulePackages = [ applesmc-next ];
  };
}
