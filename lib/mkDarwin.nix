{ inputs, ... }:
let
  nix_repo = ".nix-config";
in
{
  # Function for nix-darwin system configuration
  mkDarwinConfiguration =
    hostname: system: username:
    inputs.nix-darwin.lib.darwinSystem rec {
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
