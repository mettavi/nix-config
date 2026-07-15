{
  description = "Metta's Nix system flake";

  # Binary cache
  # this setting allows untrusted users of this flake to approve substituters interactively
  # it is only useful in a multi-user system
  # nixConfig = {
  # will be appended to the system-level substituters
  # extra-substituters = [
  # ];
  # will be appended to the system-level trusted-public-keys
  #   extra-trusted-public-keys = [
  #   ];
  # };

  inputs = {
    ####################### MAIN INPUTS ##########################

    ######### NIXOS #########
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-26_05.url = "github:NixOS/nixpkgs/release-26.05";
    nixpkgs-25_11.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Do not override cachyos-kernel nixpkgs input, otherwise there can
    # be mismatch between patches and kernel version
    cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    # fan daemon for T2 macs (for host lady on MBP)
    t2fanrd.url = "github:GnomedDev/T2FanRD";
    # Manages Podman containers and networks on NixOS via Quadlet
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    ####### HOME_MANAGER #########
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ######## NIX-DARWIN ########
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # for nix-darwin
    # migrate to this input when 26.05 stable is released, which is the last version to support intel darwin
    # nixpkgs-26_05.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    # HOMEBREW
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      # inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    # if mutableTaps is disabled in homebrew.nix, these taps must be declared here AND in homebrew.nix
    # NB: do not use the brew "shorthand" which excludes the "homebrew-" part of the GH url
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    # Removed due to bug with sbcl dependency on intel darwin, see https://github.com/hraban/mac-app-util/issues/20
    # mac-app-util = {
    #   url = "github:hraban/mac-app-util";
    #   inputs.nixpkgs.follows = "nixpkgs-darwin";
    # };

    ####################### PERSONAL REPOS #######################
    secrets = {
      # use this address with ssh keys after initial setup
      url = "git+ssh://git@github.com/mettavi/nix-secrets.git?ref=main&shallow=1";
      # use this address with a GH personal access token (PAT) for initial install
      # NB: add the PAT directly to the nix.conf file (using the nix.settings flake attribute) with "access-tokens = github.com=<PAT>"
      # url = "github:mettavi/nix-secrets";
      inputs = { };
    };

    ################# OTHER APPS (alphabetical) ##################
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dove = {
      url = "git+https://gitlab.com/celenityy/Dove.git?ref=pages";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.phoenix.follows = "phoenix";
    };
    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      # essential library functions from the nixpkgs collection
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    jellarr = {
      url = "github:venkyr77/jellarr/faeb5c70999592cb7763e68a93924503df0ada9e";
    };
    nixCats = {
      url = "github:BirdeeHub/nixCats-nvim";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # use a ready-made database for nix-index/nix-locate rather than building it locally
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    phoenix = {
      url = "git+https://gitlab.com/celenityy/Phoenix.git?ref=pages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # These 2 are already in nixpkgs, however this ensures you always fetch the most up to date version!
    plugins-lze = {
      url = "github:BirdeeHub/lze";
      flake = false;
    };
    plugins-lzextras = {
      url = "github:BirdeeHub/lzextras";
      flake = false;
    };
    plugins-vim-maximizer = {
      url = "github:szw/vim-maximizer";
      flake = false;
    };
    sops-nixos = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix-darwin = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    tmux-which-key = {
      url = "github:mettavi/tmux-which-key/d02a3280352d27164354355e78ad20284de46b07";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # install a pinned version of a nix package with:
    # specific_package.url = "github:nixos/nixpkgs/specific_commit_hash_from_nixhub.io";
    # inputs.specific_package.legacyPackages.${pkgs.stdenv.hostPlatform.system}.package_name_from_nixhub.io
  };
  outputs =
    inputs@{
      self,
      ...
    }:

    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import an internal flake module: ./other.nix
        # To import an external flake module:
        #   1. Add foo to inputs
        #   2. Add foo as a parameter to the outputs function
        #   3. Add here: foo.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      # perSystem = { config, self', inputs', pkgs, system, ... }: {
      # Per-system attributes can be defined here. The self' and inputs'
      # module parameters provide easy access to attributes of the same
      # system.

      # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
      #   packages.default = pkgs.hello;
      # };

      flake =
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
        let
          mkDarwin = import ./lib/mkDarwin.nix { inherit inputs self; };
          mkNixos = import ./lib/mkNixos.nix { inherit inputs self; };
          initNixos = import ./lib/initNixos.nix { inherit inputs; };
        in
        {
          nix_repo = ".nix-config";
          secrets_path = toString inputs.secrets;

          # DARWIN-REBUILD BUILDS
          # Build darwin flake using:
          # $ darwin-rebuild build --flake .#hostname
          darwinConfigurations = {
            "mack" = mkDarwin.mkDarwinConfiguration "mack" "x86_64-darwin";
          };

          # NIXOS-REBUILD BUILDS
          # Build nixos flake using:
          # nixos-rebuild build --flake .#hostname
          nixosConfigurations = {
            "oona" = mkNixos.mkNixosConfiguration "oona" "x86_64-linux";
            "lady" = mkNixos.mkNixosConfiguration "lady" "x86_64-linux";
          };

          # run "nix build -L .#nixosConfigurations.nix-guest.config.system.build.vm" to create the guest vm
          # launch the vm with "QEMU_KERNEL_PARAMS=console=ttyS0 ./result/bin/run-nixos-vm -nographic; reset"
          # for ssh connections, add QEMU_NET_OPTS="hostfwd=tcp:127.0.0.1:2222-:22"
          # to set up port fowarding to the guest and add the "-p 2222" flag to ssh
          nixosConfigurations.nix-guest = inputs.nixpkgs-26_05.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./hosts/nix-guest/configuration.nix
            ];
          };

          ################################  NIXOS-ANYWHERE BUILDS  ######################################

          # nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
          # --flake <path to configuration>#<configuration name> -i <identity_file> --build-on remote \
          # --print-build-log --target-host username@<ip address>
          # nixosConfigurations = {
          #   "blue" = initNixos.mkNixosConfiguration "blue" "x86_64-linux" "timotheos" "nixpkgs-26_05";
          # };

        };
    };
}
