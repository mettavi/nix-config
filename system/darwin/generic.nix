{
  pkgs,
  ...
}:
{
  nix = {
    enable = true;
    package = pkgs.lixPackageSets.stable.lix;
    settings = {

      # WARNING: This is for temporary use to authenticate while setting up the ssh keys with the sops-nix secrets system.
      # Do not commit this to git under any circumstances!

      # access-tokens = [
      #   "github.com=<personal-access-token-here>"
      # ];
    };
  };
  nixpkgs = {
    overlays = [
      (import ../overlays/darwin/default.nix)
    ];
  };
}
