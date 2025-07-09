{
  config,
  hostname,
  inputs,
  nix_repo,
  options,
  username,
  ...
}:
{
  nix = {
    channel.enable = false;
    # enable automatic garbage collection and store optimisation
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d"; # Delete generations older than 30 days
      persistent = true;
    };
    # this ensures $NIX_PATH is set to an immutable location in the nix-store
    nixPath = options.nix.nixPath.default ++ [
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
    settings = {
      extra-substituters = [
        "https://nixpkgs.cachix.org"
        "https://nix-community.cachix.org"
        "https://cachix.cachix.org"
        "https://yazi.cachix.org"
        "https://mettavi.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
        "mettavi.cachix.org-1:rYvLGZOMT4z4hK7u5pzrbt8svJ/2JcUA/PTa1bQx4FU="
      ];
      nix-path = config.nix.nixPath;
      trusted-users = [
        "@staff"
        "root"
      ];
    };
  };
}
