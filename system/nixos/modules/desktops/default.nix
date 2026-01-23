{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
with lib;
let
  cfg = config.mettavi.system.desktops;
in
{
  imports =
    let
      dirs = filterAttrs (n: v: v != null && !(hasPrefix "_" n) && (v == "directory")) (readDir ./.);
      paths = map (x: "${toString ./.}/${x}") (attrNames dirs);
    in
    paths;

  # disable this option for any hosts not running on the more modern wayland display-server protocol
  options.mettavi.system.desktops = {
    wayland = mkOption {
      description = "Whether the display server protocol is wayland";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.wayland {
    environment = {
      sessionVariables = {
        # Forces Wayland backend for applications using Ozone (eg. in all chrome and most electron apps)
        NIXOS_OZONE_WL = "1";
      };
      systemPackages = with pkgs; [
        wayland-utils # wayland-info utility
      ];
    };
  };
}
