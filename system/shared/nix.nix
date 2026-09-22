{ inputs, ... }:
{
  nixpkgs = {
    overlays = [
      (import ../overlays/shared)
      (inputs.tmux-which-key.overlays.default)
    ];
    # nixpkgs.config.allowBroken = true;
  };
}
