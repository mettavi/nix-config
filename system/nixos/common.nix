{
  lib,
  hostname,
  inputs,
  self,
  system,
  ...
}:
{

  imports = [
    ./default.nix
    ./modules
    ../shared
    ../shared/modules

    # MODULES FROM FLAKE INPUTS
    inputs.disko.nixosModules.disko
    # thunderbird privacy and security
    inputs.dove.nixosModules.default
    # this provides a wrapper for the nix-index package (no need to install the package separately)
    inputs.nix-index-database.nixosModules.nix-index
    # Adds the NUR overlay
    inputs.nur.modules.nixos.default
    inputs.sops-nixos.nixosModules.sops
  ];

  environment.variables = {
    # remove the default "S" to prevent truncated lines in journalctl output,
    # which causes problems with scrollback in the (eg. ghostty) terminal
    SYSTEMD_LESS = "FRXMK";
  };

  i18n = {
    defaultLocale = "en_AU.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
    };
  };

  networking.hostName = hostname;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  nixpkgs = {
    # Allow unfree packages
    config.allowUnfree = true;
    hostPlatform = "${system}";
  };

  # The Git revision of the top-level flake from which this configuration was built
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Set a safe global timezone for servers, which can be overriden on laptops etc.
  # view available values with "timedatectl list-timezones | grep <America/Australia/...>"
  time.timeZone = lib.mkDefault "UTC";

  # Centralized Home Manager orchestration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "nix-backup";
    extraSpecialArgs = {
      inherit
        hostname
        inputs
        self
        system
        ;
      inherit (self) nix_repo secrets_path;
    };
    sharedModules = [ inputs.sops-nixos.homeManagerModules.sops ];
  };
}
