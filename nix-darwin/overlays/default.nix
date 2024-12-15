{
  config,
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.overlays = [
    (import ./overlay-qtwebengine.nix)
  ];
}
