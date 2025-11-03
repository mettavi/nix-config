{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.devices.logitech;
in
{
  options.mettavi.system.devices.logitech = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure logitech devices";
    };
  };

  config = mkIf cfg.enable {
    hardware.logitech = {
      # enable support for Logitech Wireless Devices
      wireless = {
        enable = true; # installs ltunify and logitech-udev-rules packages
        enableGraphical = true; # installs solaar gui and command for extra functionality (eg. bolt connector devices)
      };
    };
  };
}
