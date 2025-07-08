{
  nixpkgs = {
    overlays = [
      (import ../overlays/shared)
    ];
    # nixpkgs.config.allowBroken = true;
  };
}
