{
  inputs,
  self,
  ...
}:
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
          system
          username
          ;
        inherit (self)
          nix_repo
          secrets_path
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
        ../system/darwin/activation.nix
        ../system/darwin/brew.nix
        ../system/darwin/generic.nix
        ../system/darwin/macos.nix
        ../system/darwin/packages.nix
        ../system/darwin/services.nix
        ../system/darwin/nix-homebrew.nix
        ../system/darwin/modules
        ../system/shared
        ../system/shared/modules
        inputs.mac-app-util.darwinModules.default
        inputs.nix-index-database.darwinModules.nix-index
        inputs.sops-nix.darwinModules.sops
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "nix-backup";
            users.${username} = import ./mkUserHome.nix;
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
