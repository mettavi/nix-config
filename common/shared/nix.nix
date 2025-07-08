{
  nixpkgs = {
    overlays = [
      (import ../overlays/shared/default.nix)
    ];
    # nixpkgs.config.allowBroken = true;
  };
}
