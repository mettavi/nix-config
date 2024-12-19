{
  description = "Metta's Darwin system flake";

  # Binary cache
  nixConfig = {
    # will be appended to the system-level substituters
    extra-substituters = [
    ];
    # will be appended to the system-level trusted-public-keys
    extra-trusted-public-keys = [
    ];
  };

  inputs = {
    # Official NixOS package source, using nixos's unstable branch by default
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-24_11.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-24_05.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # if mutableTaps is disabled in homebrew.nix, these taps must be declared here AND in homebrew.nix
    # NB: do not use the brew "shorthand" which excludes the "homebrew-" part of the GH url
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    pinentry-touchid = {
      url = "github:jorgelbg/homebrew-tap";
      flake = false;
    };
    kegworks = {
      url = "github:gcenx/homebrew-wine";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # install a pinned version of a nix package with:
    # specific_package.url = "github:nixos/nixpkgs/specific_commit_hash_from_nixhub.io";
    # inputs.specific_package.legacyPackages.${system}.package_name_from_nixhub.io
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-vscode-extensions,
      nix-index-database,
      ...
    }:
    let
      system = "x86_64-darwin";
      user = "timotheos";
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#MVs-MBP
      darwinConfigurations."MVs-MBP" = nix-darwin.lib.darwinSystem {
        # Use specialArgs to pass through inputs to nix-darwin modules
        specialArgs = {
          inherit inputs system user nixpkgs;
        };
        modules = [
          ./configuration.nix
          # nix-homebrew.darwinModules.nix-homebrew
          ./homebrew.nix
          home-manager.darwinModules.home-manager
          {
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.timotheos = import ./home.nix;
            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home-manager modules
            home-manager.extraSpecialArgs = {
              inherit inputs;
            };
          }
          # enable the default overlay from nix-vscode-extensions
          # to make more vscode extensions available
          { nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ]; }
          nix-index-database.darwinModules.nix-index
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."MVs-MBP".pkgs;
    };
}
