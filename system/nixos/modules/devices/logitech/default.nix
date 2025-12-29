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
    home-manager.users.${username} =
      { config, nixosConfig, ... }:
      let
        inherit (config.lib.file) mkOutOfStoreSymlink;
      in
      {
        home.packages =
          with pkgs.gnomeExtensions;
          lib.mkIf (nixosConfig.mettavi.system.desktops.gnome.enable) [
            solaar-extension # Allow Solaar to support certain features on non-X11 systems (eg. rules)
          ];
        dconf.settings = lib.mkIf (nixosConfig.mettavi.system.desktops.gnome.enable) {
          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = [
              "solaar-extension@sidevesh"
            ];
          };
        };
        xdg.configFile = {
          # link without copying to nix store (manage externally) - must use absolute paths
          # mkOutOfStoreSymlink is required to allow the lazy-lock.json file to be writable
          "solaar/config.yaml".source =
            mkOutOfStoreSymlink "${inputs.self}/home/nixos/dots/solaar/config.yaml";
        };
      };
  };
}
