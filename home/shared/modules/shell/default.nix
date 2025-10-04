{ lib, ... }:
with builtins;
with lib;
{
  # automatically import all default.nix files in all valid subdirectories
  imports =
    let
      dirs = filterAttrs (n: v: v != null && !(hasPrefix "_" n) && (v == "directory")) (readDir ./.);
      paths = map (x: "${toString ./.}/${x}") (attrNames dirs);
    in
    paths;
}
