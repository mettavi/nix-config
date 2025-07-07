{
  nix = {
    # enable automatic garbage collection and store optimisation
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d"; # Delete generations older than 30 days
      persistent = true;
    };
    # this ensures $NIX_PATH is set to an immutable location in the nix-store
    nixPath = [
      "nixpkgs=${inputs.nixos-pkgs}"
      "nixpkgs-overlays=${config.users.users.${username}.home}/${nix_repo}/common/overlays/shared"
      "nixos-config=${
        config.users.users.${username}.home
      }/${nix_repo}/hosts/${hostname}/configuration.nix"
      "home-manager=${inputs.home-manager}"
    ];
    optimise = {
      automatic = true;
      dates = "02:15";
    };
  };
}
