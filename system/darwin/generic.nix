{
  pkgs,
  ...
}:
{
  nix = {
    enable = true;
    package = pkgs.lixPackageSets.stable.lix;
  };
  nixpkgs = {
    overlays = [
      (import ../overlays/darwin/default.nix)
    ];
  };
}
