{ lib, ... }:
with builtins;
with lib;
{
  imports =
    let
      dirs = filterAttrs (n: v: v != null && !(hasPrefix "_" n) && (v == "directory")) (readDir ./.);
      paths = map (x: "${toString ./.}/${x}") (attrNames dirs);
    in
    paths;

  # disable this option for any hosts not running on the more modern wayland display-server protocol
  options.mettavi.system.desktops.wayland = {
    enable = mkOption {
      description = "Whether the display server protocol is wayland";
      type = types.bool;
      default = true;
    };
  };
}
