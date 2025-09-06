# shell.nix
{
  pkgs ? import <nixpkgs> { },
}:

let
  myOverlay = import ./system/overlays/darwin;
  pkgsWithOverlay = import <nixpkgs> {
    overlays = [ myOverlay ];
  };
in
pkgsWithOverlay.mkShell {
}
