{ inputs, modulesPath, ... }:
{
  # Function for NixOS system configuration
  mkNixosConfiguration =
    hostname: system: username:
    inputs.nixos-pkgs.lib.nixosSystem {
      specialArgs = {
        inherit
          hostname
          inputs
          system
          username
          ;
      };
      modules = [
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")
        inputs.disko.nixosModules.disko
        ../hosts/${hostname}/.disk-config.nix
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
      ];
    };
}
