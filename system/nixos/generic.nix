{
  config,
  hostname,
  inputs,
  lib,
  nix_repo,
  options,
  username,
  ...
}:
{
  nixpkgs = {
    overlays = [
      # Build the kernels on top of nixpkgs version in your flake.
      # Binary cache may be unavailable for the kernel/nixpkgs version combos.
      # inputs.cachyos-kernel.overlays.default

      # Alternatively: use the exact kernel versions as defined in this repo.
      # Guarantees you have binary cache.
      inputs.cachyos-kernel.overlays.pinned

      # Only use one of the two overlays!
    ];
  };
  nix = {
    channel.enable = false;
    extraOptions = # bash
      ''
        warn-dirty = false
        # import this file into nix.conf (set "access-tokens" key to my GitHub token to get a higher API threshold for rate-limiting)
        # see https://github.com/NixOS/nix/issues/6536 for more details
        !include ${config.home-manager.users.${username}.sops.secrets."users/${username}/github_token".path}
      '';
    # enable automatic garbage collection and store optimisation
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d"; # Delete generations older than 30 days
      persistent = true;
    };
    # this ensures $NIX_PATH is set to an immutable location in the nix-store
    nixPath = options.nix.nixPath.default ++ [
      "nixpkgs=flake:nixpkgs"
      "nixpkgs-overlays=${config.users.users.${username}.home}/${nix_repo}/system/overlays/shared"
      "home-manager=${inputs.home-manager}"
    ];
    optimise = {
      automatic = true;
      dates = "02:15";
    };
    settings = {

      # WARNING: This is for temporary use to authenticate while setting up the ssh keys with the sops-nix secrets system.
      # Do not commit this to git under any circumstances!

      # access-tokens = [
      #   "github.com=<personal-access-token-here>"
      # ];

      # enable flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [
        "https://nixpkgs.cachix.org"
        "https://nix-community.cachix.org"
        "https://cachix.cachix.org"
        "https://mettavi.cachix.org"
        # for nix-cachyos-kernel flake input
        "https://attic.xuyh0120.win/lantian"
      ]
      ++ lib.optionals config.home-manager.users.${username}.mettavi.shell.yazi.enable [
        "https://yazi.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        "mettavi.cachix.org-1:rYvLGZOMT4z4hK7u5pzrbt8svJ/2JcUA/PTa1bQx4FU="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ]
      ++ lib.optionals config.home-manager.users.${username}.mettavi.shell.yazi.enable [
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      ];
      trusted-users = [
        "@staff"
        "root"
      ];
    };
  };
}
