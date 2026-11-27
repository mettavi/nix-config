{ }:
import <nixpkgs> {
  overlays = [
    (import ./system/overlays/nixos/default.nix)
    (import ./system/overlays/shared/default.nix)
  ];
  config.allowUnfree = true;
}
