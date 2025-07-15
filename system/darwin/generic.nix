{
  nix = {
    # nix is now managed by the determinate nixd
    enable = false;
  };
  nixpkgs = {
    overlays = [ (import ../overlays/darwin/default.nix) ];
  };
}
