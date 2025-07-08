{
  inputs,
  ...
}:
{
  nixpkgs = {
    overlays = [
      # make more vscode extensions available
      (inputs.nix-vscode-extensions.overlays.default)
    ];
  };
}
