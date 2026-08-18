# Used by ./tasks/update
{ }:
import <nixpkgs> {
  overlays = [
    (import ./system/overlays/nixos/default.nix)
  ];
  config.nixpkgs.allowUnfree = true;
}
