# Used by ./tasks/update
{ }:
import <nixpkgs> {
  overlays = [
    (import ./common/overlays/darwin/default.nix)
  ];
  config.nixpkgs.allowUnfree = true;
}
