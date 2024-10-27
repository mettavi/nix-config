{
  description = "Metta's Darwin system flake";

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
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
