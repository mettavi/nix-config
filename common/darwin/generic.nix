{
  inputs,
  ...
}:
{
  nix = {
    nixPath = [
      # this ensures $NIX_PATH is set to an immutable location in the nix-store
      # "nixpkgs-overlays=$HOME/.dotfiles/common/darwin/overlays"
      "darwin=${inputs.nix-darwin}"
    ];
  };
}
