{ inputs, ... }:
let
  nix_repo = ".nix-config";
in
{
  # Function for NixOS system configuration
  mkNixosConfiguration =
    hostname: system: username:
    inputs.nixos-pkgs.lib.nixosSystem rec {
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
            isNormalUser = true;
            home = "/home/${username}";
            # allow user to configure networking and use sudo
            extraGroups = [
              "networkmanager"
              "wheel"
            ];
          };
        }
        ../hosts/${hostname}/hardware-configuration.nix
        ../common/linux
        ../common/shared
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "nix-backup";
            users.${username} = ../common/users/${username};
            extraSpecialArgs = specialArgs;
            sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
          };
        }
      ];
    };
}
