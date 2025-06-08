{
  nix = {
    enable = false;
  };
  nixpkgs = {
    overlays = [ (import ../overlays/darwin/default.nix) ];
  };
}
