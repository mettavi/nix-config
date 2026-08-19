{
  config,
  hostname,
  inputs,
  nix_repo,
  options,
  pkgs,
  username,
  ...
}:
{
  nix = {
    enable = true;
    channel.enable = false;
    # this ensures $NIX_PATH is set to an immutable location in the nix-store
    nixPath = options.nix.nixPath.default ++ [
      "nixpkgs=${inputs.nixpkgs-darwin}"
      "nixpkgs-overlays=${config.users.users.${username}.home}/${nix_repo}/system/overlays/shared"
      "darwin-config=${
        config.users.users.${username}.home
      }/${nix_repo}/hosts/${hostname}/configuration.nix"
      "home-manager=${inputs.home-manager}"
    ];
    package = pkgs.lixPackageSets.stable.lix;
  };
  nixpkgs = {
    overlays = [
      (import ../overlays/darwin/default.nix)
    ];
  };
}
