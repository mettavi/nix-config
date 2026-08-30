{
  inputs,
  lib,
  self,
  ...
}:
let
  # -------------------------------------------------------------
  # 1. DATA MATRICES: Centralized configurations list
  # -------------------------------------------------------------
  nixosHosts = {
    oona = {
      system = "x86_64-linux";
      channel = "nixpkgs";
      profile = "physical";
    };
    lady = {
      system = "x86_64-linux";
      channel = "nixpkgs";
      profile = "physical";
    };
    blue = {
      system = "x86_64-linux";
      channel = "nixpkgs-26_05";
      profile = "physical";
    };
    remus = {
      system = "x86_64-linux";
      channel = "nixpkgs-26_05";
      profile = "physical";
    };
    ################################# NIXOS QEMU VMS #############################################
    # run "nix build -L .#nixosConfigurations.nix-guest.config.system.build.vm" to create the guest vm
    # launch the vm with "QEMU_KERNEL_PARAMS=console=ttyS0 ./result/bin/run-nixos-vm -nographic; reset"
    # For ssh connections, add QEMU_NET_OPTS="hostfwd=tcp:127.0.0.1:2222-:22"...
    # to set up port fowarding to the guest and add the "-p 2222" flag to ssh.
    # See https://nix.dev/tutorials/nixos/nixos-configuration-on-vm and
    # https://dev.to/vst/running-nixos-guests-on-qemu-3lpa
    # 🌟 Fully-Equipped VM (Inherits common.nix, home-manager, users, etc.)
    nix-guest-full = {
      system = "x86_64-linux";
      channel = "nixpkgs-26_05";
      profile = "equipped-vm";
    };
    # 🌟 Barebones Experimental VMs (Completely clean, no global overrides)
    nix-guest = {
      system = "x86_64-linux";
      channel = "nixpkgs-26_05";
      profile = "barebones-vm";
    };
    # test-vm2   = { system = "x86_64-linux"; channel = "nixpkgs"; profile = "barebones-vm"; }; # Easy to add more!
  };

  darwinHosts = {
    mack = {
      system = "x86_64-darwin";
    };
  };

  ################################  NIXOS-ANYWHERE BUILDS  ######################################
  # nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  # --flake <path to configuration>#<configuration name> -i <identity_file> --build-on remote \
  # --print-build-log --target-host username@<ip address>
  initHosts = {
    # Nixos-anywhere bootstrap environment targets
    # remus-init = {
    #   system = "x86_64-linux";
    #   channel = "nixpkgs-26_05";
    #   targetHost = "remus";
    #   username = "timotheos";
    # };
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
  # Build nixos flake using: sudo nixos-rebuild switch --flake .#hostname
  flake.nixosConfigurations =
    (builtins.mapAttrs (
      hostname: hostAttrs:
      let
        hostNixpkgs = inputs."${hostAttrs.channel}";
      in
      hostNixpkgs.lib.nixosSystem {
        inherit (hostAttrs) system;
        specialArgs = sharedArgs hostAttrs.system hostname;
        modules = [
          ./hosts/${hostname}/configuration.nix
        ]
        # If the host is physical, it gets the hardware scan
        ++ (lib.optional (hostAttrs.profile == "physical") ./hosts/${hostname}/hardware-configuration.nix)
        # If the host is NOT a barebones VM, it inherits your whole global setup
        ++ (lib.optionals (hostAttrs.profile != "barebones-vm") [
          ./system/nixos/common.nix
          inputs."home-manager${
            if hostAttrs.channel == "nixpkgs" then "" else "-26_05"
          }".nixosModules.home-manager
        ]);
      }
    ) nixosHosts)

    # --- 🌟 Bootstrapping NixOS Profiles ---
    # nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
    # --flake <path to configuration>#<configuration name> -i <identity_file> --build-on remote \
    # --print-build-log --target-host username@<ip address>
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
            # The Git revision of the top-level flake from which this configuration was built
            system.configurationRevision = self.rev or self.dirtyRev or null;

            users.users.${initAttrs.username} = {
              isNormalUser = true;
              home = "/home/${initAttrs.username}";
              # allow the admin user to configure networking and use sudo
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
              # Enable the OpenSSH daemon
              enable = true;
              # create a host key
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

  # --- 🌟 Darwin Profiles ---
  # Build darwin flake using: sudo darwin-rebuild switch --flake .#hostname
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

        # this provides a wrapper for the nix-index package (no need to install separately)
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
