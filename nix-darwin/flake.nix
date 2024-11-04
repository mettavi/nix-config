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
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # the homebrew taps below are only required if mutableTaps is disabled
    # homebrew-core = {
    #   url = "github:homebrew/homebrew-core";
    #   flake = false;
    # };
    # homebrew-cask = {
    #   url = "github:homebrew/homebrew-cask";
    #   flake = false;
    # };
    # homebrew-bundle = {
    #   url = "github:homebrew/homebrew-bundle";
    #   flake = false;
    # };
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # patched version of nh (nix helper) for macOS
    nh_darwin.url = "github:ToyVo/nh_darwin";
    # install a pinned version of a nix package
    # specific_package.url = "github:nixos/nixpkgs/specific_commit_hash_from_nixhub.io";
    # install with "inputs.specific_package.legacyPackages.${system}.package_name"
  };
  outputs =
    inputs@{
      self,
      nix-darwin,
      # nixpkgs,
      nixpkgs-unstable,
      nix-homebrew,
      # homebrew-core,
      # homebrew-cask,
      # homebrew-bundle,
      home-manager,
      nix-vscode-extensions,
      nh_darwin,
      ...
    }:
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#MVs-MBP
      darwinConfigurations."MVs-MBP" = nix-darwin.lib.darwinSystem {
        # Set all inputs parameters as special arguments for all submodules,
        # so you can directly use all dependencies in inputs in submodules
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.timotheos = import ./home.nix;
            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
          # enable the default overlay from nix-vscode-extensions
          # to make more vscode extensions available
          { nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ]; }
          nh_darwin.nixDarwinModules.prebuiltin
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."MVs-MBP".pkgs;
    };
}
