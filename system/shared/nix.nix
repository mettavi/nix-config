{ inputs, ... }:
{
  nixpkgs = {
    overlays = [
      (import ../overlays/shared)
      # make more vscode extensions available
      (inputs.nix-vscode-extensions.overlays.default)
    ];
    # nixpkgs.config.allowBroken = true;
  };
}
