{ inputs, ... }:
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
        inputs.disko.nixosModules.disko
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
          };
          programs = {
            firefox.enable = true;
            git.enable = true;
            vim.enable = true;
          };
          # The Git revision of the top-level flake from which this configuration was built
          system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
        }
      ];
    };
}
