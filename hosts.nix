{ inputs, self, ... }:
let
  # -------------------------------------------------------------
  # 1. DATA MATRICES: Centralized configurations list
  # -------------------------------------------------------------
  nixosHosts = {
    oona = {
      system = "x86_64-linux";
      channel = "nixpkgs";
    };
    lady = {
      system = "x86_64-linux";
      channel = "nixpkgs";
    };
    blue = {
      system = "x86_64-linux";
      channel = "nixpkgs-26_05";
    };
    remus = {
      system = "x86_64-linux";
      channel = "nixpkgs-26_05";
    };
  };

  darwinHosts = {
    mack = {
      system = "x86_64-darwin";
    };
  };

  initHosts = {
    # Nixos-anywhere bootstrap environment targets
    remus-init = {
      system = "x86_64-linux";
      channel = "nixpkgs-26_05";
      targetHost = "remus";
      username = "timotheos";
    };
  };

  # -------------------------------------------------------------
  # 2. SHARED INJECTORS: Reusable variables block
  # -------------------------------------------------------------
  sharedArgs = system: hostname: {
    inherit
      hostname
      inputs
      self
      system
      ;
    inherit (self) nix_repo secrets_path;
  };

in
{
  # -------------------------------------------------------------
  # 3. GENERATION GENERATORS: Mapping layouts to flake-parts
  # -------------------------------------------------------------

  # --- Standard NixOS Configs ---
  flake.nixosConfigurations =
    (builtins.mapAttrs (
      hostname: hostAttrs:
      inputs."${hostAttrs.channel}".lib.nixosSystem {
        inherit (hostAttrs) system;
        specialArgs = sharedArgs hostAttrs.system hostname;
        modules = [
          ./hosts/${hostname}/configuration.nix
          ./hosts/${hostname}/hardware-configuration.nix
          ./system/nixos/common.nix
          inputs."home-manager${
            if hostAttrs.channel == "nixpkgs" then "" else "-26_05"
          }".nixosModules.home-manager
        ];
      }
    ) nixosHosts)

    # --- 🌟 Bootstrapping NixOS Profiles (initNixos replacement) ---
    // (builtins.mapAttrs (
      initName: initAttrs:
      inputs."${initAttrs.channel}".lib.nixosSystem {
        inherit (initAttrs) system;
        specialArgs = {
          hostname = initAttrs.targetHost;
          inherit inputs self;
          inherit (initAttrs) username system;
        };
        modules = [
          inputs.disko.nixosModules.disko
          ./hosts/${initAttrs.targetHost}/configuration.nix
          {
            networking.hostName = initAttrs.targetHost;
            nixpkgs.hostPlatform = initAttrs.system;
            nixpkgs.config.allowUnfree = true;
            system.configurationRevision = self.rev or self.dirtyRev or null;

            users.users.${initAttrs.username} = {
              isNormalUser = true;
              home = "/home/${initAttrs.username}";
              extraGroups = [
                "networkmanager"
                "wheel"
              ];
            };
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
            programs.git.enable = true;
            programs.vim.enable = true;
            services.openssh = {
              enable = true;
              hostKeys = [
                {
                  comment = "root@${initAttrs.targetHost}";
                  path = "/etc/ssh/ssh_${initAttrs.targetHost}_ed25519_key";
                  rounds = 100;
                  type = "ed25519";
                }
              ];
              settings.PermitRootLogin = "prohibit-password";
            };
          }
        ];
      }
    ) initHosts);

  # --- 🌟 Darwin Profiles (mkDarwin replacement) ---
  flake.darwinConfigurations = builtins.mapAttrs (
    hostname: hostAttrs:
    inputs.nix-darwin.lib.darwinSystem {
      inherit (hostAttrs) system;
      specialArgs = sharedArgs hostAttrs.system hostname;
      modules = [
        ./hosts/${hostname}/configuration.nix
        {
          networking.hostName = hostname;
          nixpkgs.hostPlatform = hostAttrs.system;
          nixpkgs.config.allowUnfree = true;
          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
          nix.extraOptions = "warn-dirty = false";
        }
        ./system/darwin/activation.nix
        ./system/darwin/brew.nix
        ./system/darwin/generic.nix
        ./system/darwin/macos.nix
        ./system/darwin/packages.nix
        ./system/darwin/services.nix
        ./system/darwin/nix-homebrew.nix
        ./system/darwin/modules
        ./system/shared
        ./system/shared/modules

        inputs.nix-index-database.darwinModules.nix-index
        inputs.sops-nix-darwin.darwinModules.sops
        inputs.home-manager-darwin.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "nix-backup";
            extraSpecialArgs = sharedArgs hostAttrs.system hostname;
            sharedModules = [ inputs.sops-nix-darwin.homeManagerModules.sops ];
          };
        }
      ];
    }
  ) darwinHosts;
}
