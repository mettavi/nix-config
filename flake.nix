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
    ####################### MAIN INPUTS ##########################

    ######## NIX-DARWIN ########
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # for nix-darwin
    nixpkgs-24_11.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    # install from PR https://github.com/NixOS/nixpkgs/pull/451386 until it is merged to nixpkgs-unstable
    # TODO: Check status at https://nixpk.gs/pr-tracker.html?pr=451386
    nixpkgs-rubyfix = {
      url = "github:NixOS/nixpkgs/cdb57da081701af98fcc5944dc8e174548f5584f";
      # causes error "warning: input 'nixpkgs-rubyfix' has an override for a non-existent input 'nixpkgs'"
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # HOMEBREW
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

    ######### NIXOS #########
    nixos-pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    ####### HOME_MANAGER #########
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ####################### PERSONAL REPOS #######################
    secrets = {
      url = "git+ssh://git@github.com/mettavi/nix-secrets.git?ref=main&shallow=1";
      inputs = { };
    };

    ################# OTHER APPS (alphabetical) ##################
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };
    kegworks = {
      url = "github:Kegworks-App/Kegworks";
      flake = false;
    };
    nixCats = {
      url = "github:BirdeeHub/nixCats-nvim";
    };
    # Removed due to bug with sbcl dependency on intel darwin, see https://github.com/hraban/mac-app-util/issues/20
    # mac-app-util = {
    #   url = "github:hraban/mac-app-util";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # use a ready-made database for nix-index/nix-locate rather than building it locally
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
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
      mkDarwin = import ./lib/mkDarwin.nix { inherit inputs self; };
      mkNixos = import ./lib/mkNixos.nix { inherit inputs self; };
      # initNixos = import ./lib/initNixos.nix { inherit inputs; };
    in
    {
      nix_repo = ".nix-config";
      secrets_path = builtins.toString inputs.secrets;

      # DARWIN-REBUILD BUILDS
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#hostname
      darwinConfigurations = {
        "mack" = mkDarwin.mkDarwinConfiguration "mack" "x86_64-darwin";
      };

      # NIXOS-REBUILD BUILDS
      # Build nixos flake using:
      # nixos-rebuild build --flake .#hostname
      nixosConfigurations = {
        "oona" = mkNixos.mkNixosConfiguration "oona" "x86_64-linux";
        "lady" = mkNixos.mkNixosConfiguration "lady" "x86_64-linux";
        "salina" = mkNixos.mkNixosConfiguration "salina" "aarch64-linux";
      };

      ################################  NIXOS-ANYWHERE BUILDS  ######################################

      # nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
      # --flake <path to configuration>#<configuration name> -i <identity_file> --build-on remote \
      # --print-build-log --target-host username@<ip address>
      # nixosConfigurations = {
      # "oona" = initNixos.mkNixosConfiguration "oona" "x86_64-linux" "timotheos";
      # "salina" = initNixos.mkNixosConfiguration "salina" "aarch64-linux" "timotheos";
      # "remus" = initNixos.mkNixosConfiguration "remus" "x86_64-linux" "timotheos";
      # };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."mack".pkgs;

    };
}
