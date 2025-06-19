{
  description = "Metta's Nix system flake";

  # Binary cache
  # this setting allows untrusted users of this flake to approve substituters interactively
  # it is only useful in a multi-user system
  # nixConfig = {
  # will be appended to the system-level substituters
  # extra-substituters = [
  # ];
  # will be appended to the system-level trusted-public-keys
  #   extra-trusted-public-keys = [
  #   ];
  # };

  inputs = {
    # MAIN INPUTS
    # Official NixOS package source, using nixos's unstable branch by default
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # for nix-darwin
    nixos-pkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # for nixOS
    nixpkgs-24_11.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    # nixpkgs-24_05.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      # inputs.nixpkgs.follows = "nixpkgs";
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

    # OTHER APPS (alphabetical)
    kegworks = {
      url = "github:Kegworks-App/Kegworks";
      flake = false;
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pinentry-touchid = {
      url = "github:jorgelbg/homebrew-tap";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      nixos-pkgs,
      nix-index-database,
      sops-nix,
      mac-app-util,
      ...
    }:
    let

      nix_repo = ".nix-config";

      # Function for nix-darwin system configuration
      mkDarwinConfiguration =
        hostname: system: username:
        nix-darwin.lib.darwinSystem rec {
          # Use specialArgs to pass through inputs to nix-darwin modules
          specialArgs = {
            inherit
              hostname
              inputs
              nixpkgs
              nix_repo
              self
              system
              username
              ;
          };
          modules = [
            ./hosts/${hostname}/configuration.nix
            ./common/darwin/nix-homebrew.nix
            ./common/shared
            mac-app-util.darwinModules.default
            nix-index-database.darwinModules.nix-index
            sops-nix.darwinModules.sops
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "nix-backup";
                users.${username} = ./common/users/${username};
                extraSpecialArgs = specialArgs;
                sharedModules = [
                  mac-app-util.homeManagerModules.default
                  sops-nix.homeManagerModules.sops
                ];
              };
            }
          ];
        };

      # Function for NixOS system configuration
      mkNixosConfiguration =
        hostname: system: username:
        nixpkgs.lib.nixosSystem rec {
          specialArgs = {
            inherit
              hostname
              inputs
              nixos-pkgs
              nix_repo
              self
              system
              username
              ;
          };
          modules = [
            ./hosts/${hostname}/configuration.nix
            ./common/shared
            sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "nix-backup";
                users.${username} = ./common/users/${username};
                extraSpecialArgs = specialArgs;
                sharedModules = [ sops-nix.homeManagerModules.sops ];
              };
            }
          ];
        };

    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mack
      darwinConfigurations = {
        "mack" = mkDarwinConfiguration "mack" "x86_64-darwin" "timotheos";
      };

      # Build nixos flake using:
      # nixos-rebuild build --flake .#oona
      nixosConfigurations = {
        "oona" = mkNixosConfiguration "oona" "x86_64-linux" "timotheos";
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mack".pkgs;

    };
}
