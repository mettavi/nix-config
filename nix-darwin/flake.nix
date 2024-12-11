{
  description = "Metta's Darwin system flake";

  # Binary cache
  nixConfig = {
    # will be appended to the system-level substituters
    extra-substituters = [
      # nh_darwin - nix helper (builds for aarch64 and x86_64, linux and darwin).
      "https://toyvo.cachix.org"
    ];
    # will be appended to the system-level trusted-public-keys
    extra-trusted-public-keys = [
      "toyvo.cachix.org-1:s++CG1te6YaS9mjICre0Ybbya2o/S9fZIyDNGiD4UXs="
    ];
  };

  inputs = {
    # Official NixOS package source, using nixos's unstable branch by default
    nixpkgs-24_11.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-24_05.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # the homebrew taps below are only required if mutableTaps is disabled in homebrew.nix
    # NB: do not use the brew "shorthand" which excludes the "homebrew-" part of the GH url
    # these taps must also be declared in homebrew.nix
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

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # patched version of nh (nix helper) for macOS
    nh_darwin.url = "github:ToyVo/nh_darwin";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # install a pinned version of a nix package with:
    # specific_package.url = "github:nixos/nixpkgs/specific_commit_hash_from_nixhub.io";
    # inputs.specific_package.legacyPackages.${system}.package_name_from_nixhub.io
    qtwebengine-6_7_0.url = "github:NixOS/nixpkgs/3281bec7174f679eabf584591e75979a258d8c40";
  };
  outputs =
    inputs@{
      self,
      nix-darwin,
      home-manager,
      nix-vscode-extensions,
      nh_darwin,
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
          inherit inputs system user;
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
          nh_darwin.nixDarwinModules.prebuiltin
          nix-index-database.darwinModules.nix-index
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."MVs-MBP".pkgs;
    };
}
