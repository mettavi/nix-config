{
  inputs,
  self,
  ...
}:
{
  # Function for NixOS system configuration
  mkNixosConfiguration =
    hostname: system:
    inputs.nixos-pkgs.lib.nixosSystem rec {
      inherit system;
      specialArgs = {
        inherit
          hostname
          inputs
          ;
        inherit (self)
          nix_repo
          secrets_path
          ;
      };
      modules = [
        inputs.disko.nixosModules.disko
        ../hosts/${hostname}/configuration.nix
        {
          users = {
            # existing passwords on the system will not be overwritten by the nix config unless this is set to false
            # NB: Set this only for specific hosts rather than globally
            # mutableUsers = false;
          };
          environment.variables = {
            # remove the default "S" to prevent truncated lines in journalctl output,
            # which causes problems with scrollback in the (ghostty) terminal
            SYSTEMD_LESS = "FRXMK";
          };
          # Select internationalisation properties.
          time.timeZone = "Australia/Melbourne";
          i18n = {
            defaultLocale = "en_AU.UTF-8";
            extraLocaleSettings = {
              LC_ADDRESS = "en_AU.UTF-8";
              LC_IDENTIFICATION = "en_AU.UTF-8";
              LC_MEASUREMENT = "en_AU.UTF-8";
              LC_MONETARY = "en_AU.UTF-8";
              LC_NAME = "en_AU.UTF-8";
              LC_NUMERIC = "en_AU.UTF-8";
              LC_PAPER = "en_AU.UTF-8";
              LC_TELEPHONE = "en_AU.UTF-8";
              LC_TIME = "en_AU.UTF-8";
            };
          };
          networking.hostName = "${hostname}";
          nixpkgs = {
            # Allow unfree packages
            config.allowUnfree = true;
            hostPlatform = "${system}";
          };
          # The Git revision of the top-level flake from which this configuration was built
          system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
        }
        # Include the results of the hardware scan
        ../hosts/${hostname}/hardware-configuration.nix
        ../system/nixos
        ../system/nixos/modules
        ../system/shared
        ../system/shared/modules
        inputs.sops-nixos.nixosModules.sops
        # this provides a wrapper for the nix-index package (no need to install the package separately)
        inputs.nix-index-database.nixosModules.nix-index
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "nix-backup";
            extraSpecialArgs = specialArgs;
            sharedModules = [ inputs.sops-nixos.homeManagerModules.sops ];
          };
        }
      ];
    };
}
