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

    inputs.disko.nixosModules.disko
    inputs.dove.nixosModules.default
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nur.modules.nixos.default
    inputs.sops-nixos.nixosModules.sops
  ];

  # The safe global default timezone you wanted to apply
  time.timeZone = lib.mkDefault "UTC";

  networking.hostName = hostname;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  environment.variables = {
    SYSTEMD_LESS = "FRXMK";
  };

  i18n = {
    defaultLocale = "en_AU.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = "${system}";
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

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
