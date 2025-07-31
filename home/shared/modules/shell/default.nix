{ lib, ... }:
with builtins;
with lib;
{
  options.nyx.modules.shell = {
    default = mkOption {
      type = types.enum [
        "zsh"
        "bash"
      ];
      default = "zsh";
      description = "Set the user's default shell";
    };
  };
  # automatically import all default.nix files in all valid subdirectories
  imports =
    let
      dirs = filterAttrs (n: v: v != null && !(hasPrefix "_" n) && (v == "directory")) (readDir ./.);
      paths = map (x: "${toString ./.}/${x}") (attrNames dirs);
    in
    paths;
}
