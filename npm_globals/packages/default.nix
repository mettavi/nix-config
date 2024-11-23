# Custom packages, that can be defined similarly to ones from nixpkgs
# Build them using 'nix build .#example'
pkgs: {
  learnyoubash = pkgs.callPackage ./learnyoubash { };
}
