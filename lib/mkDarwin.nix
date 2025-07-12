{ inputs, ... }:
let
  nix_repo = ".nix-config";
in
{
  # Function for nix-darwin system configuration
  mkDarwinConfiguration =
    hostname: system: username:
    inputs.nix-darwin.lib.darwinSystem rec {
      system = "${system}";
      # Use specialArgs to pass through inputs to nix-darwin modules
      specialArgs = {
        inherit
          hostname
          inputs
          nix_repo
          system
          username
          ;
      };

      modules = [
        ../hosts/${hostname}/configuration.nix
        {
          networking.hostName = "${hostname}";
          nix = {
            extraOptions = ''
              warn-dirty = false
            '';
            settings = {
              # enable flakes
              experimental-features = [
                "nix-command"
                "flakes"
              ];
            };
          };
          nixpkgs = {
            # Allow unfree packages
            config.allowUnfree = true;
            hostPlatform = "${system}";
            overlays = [
              # make more vscode extensions available
              (inputs.nix-vscode-extensions.overlays.default)
            ];
          };
          users.users.${username} = {
            name = "${username}";
            home = "/Users/${username}";
          };
        }
        ../common/darwin
        ../common/darwin/nix-homebrew.nix
        ../common/shared
        inputs.mac-app-util.darwinModules.default
        inputs.nix-index-database.darwinModules.nix-index
        inputs.sops-nix.darwinModules.sops
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "nix-backup";
            users.${username} = ../common/users/${username};
            extraSpecialArgs = specialArgs;
            sharedModules = [
              inputs.mac-app-util.homeManagerModules.default
              inputs.sops-nix.homeManagerModules.sops
            ];
          };
        }
      ];
    };
}
