# shell.nix to import overlays for update script
{ }:

let
  pkgsWithOverlay = import <nixpkgs> {
    # also import nixos overlays here if necessary
    overlays = [ (import ./system/overlays/darwin) ];
  };
in
pkgsWithOverlay.mkShell {
}
