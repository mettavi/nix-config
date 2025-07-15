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
            overlays = [
              # make more vscode extensions available
              (inputs.nix-vscode-extensions.overlays.default)
            ];
          };
          programs = {
            firefox.enable = true;
            git.enable = true;
            vim.enable = true;
          };
          # The Git revision of the top-level flake from which this configuration was built
          system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
        }
        ../hosts/${hostname}/hardware-configuration.nix
        ../system/linux
        ../system/shared
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "nix-backup";
            users.${username} = ../users/${username};
            extraSpecialArgs = specialArgs;
            sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
          };
        }
      ];
    };
}
