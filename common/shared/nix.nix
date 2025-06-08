{
  inputs,
  ...
}:
{
  nix = {
    enable = false;
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      (import ../overlays/shared/default.nix)
      # make more vscode extensions available
      (inputs.nix-vscode-extensions.overlays.default)
    ];
    # nixpkgs.config.allowBroken = true;
  };
}
