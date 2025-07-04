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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      ...
    }:
    let

      mkDarwin = import ./lib/mkDarwin.nix { inherit inputs; };
      # mkNixos = import ./lib/mkNixos.nix { inherit inputs; };
      initNixos = import ./lib/initNixos.nix;

    in
    {

      # DARWIN-REBUILD BUILDS
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#hostname
      darwinConfigurations = {
        "mack" = mkDarwin.mkDarwinConfiguration "mack" "x86_64-darwin" "timotheos";
      };

      # NIXOS-REBUILD BUILDS
      # Build nixos flake using:
      # nixos-rebuild build --flake .#hostname
      # nixosConfigurations = {
      #   "oona" = mkNixos.mkNixosConfiguration "oona" "x86_64-linux" "timotheos";
      # };

      ################################  NIXOS-ANYWHERE BUILDS  ######################################

      # nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
      # --flake <path to configuration>#<configuration name> -i <identity_file> --build-on remote \
      # --print-build-log --target-host username@<ip address>
      nixosConfigurations = {
        "oona" = initNixos.mkNixosConfiguration "oona" "x86_64-linux" "timotheos";
        "salina" = initNixos.mkNixosConfiguration "salina" "aarch64-linux" "timotheos";
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mack".pkgs;

    };
}
