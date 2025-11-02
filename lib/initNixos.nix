{ inputs, ... }:
{
  # Function for NixOS system configuration
  mkNixosConfiguration =
    hostname: system: username:
    inputs.nixos-pkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          hostname
          inputs
          username
          ;
      };
      modules = [
        inputs.disko.nixosModules.disko
        ../hosts/${hostname}/configuration.nix
        {
          users.users.${username} = {
            isNormalUser = true;
            hashedPassword = "$y$j9T$AO6jdJHZ7Ep7tR2s/it0X/$1tSMbRECa1oOl.tJOeT46iKaCR9Cc0M6YkQliKZ1zsB";
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
            git.enable = true;
            vim.enable = true;
          };
          # Enable the OpenSSH daemon.
          services = {
            openssh = {
              enable = true;
              # create a host key
              hostKeys = [
                {
                  comment = "root@${hostname}";
                  path = "/etc/ssh/ssh_${hostname}_ed25519_key";
                  rounds = 100;
                  type = "ed25519";
                }
              ];
            };
          };
          # The Git revision of the top-level flake from which this configuration was built
          system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
        }
      ];
    };
}
