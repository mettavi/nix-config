{
  description = "Metta's Darwin system flake";

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs =
    inputs@{
      self,
      nix-darwin,
      # nixpkgs,
      nixpkgs-unstable,
      nix-homebrew,
      home-manager,
      nix-vscode-extensions,
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
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              # enableRosetta = true;

              # User owning the Homebrew prefix
              user = "timotheos";

              # Automatically migrate existing Homebrew installations
              autoMigrate = true;
            };
          }
          home-manager.darwinModules.home-manager
          {
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.timotheos = import ./home.nix;
          }
          # enable the default overlay from nix-vscode-extensions
          # to make more vscode extensions available
          { nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ]; }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."MVs-MBP".pkgs;
    };
}
