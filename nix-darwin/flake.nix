{
  description = "Metta's Darwin system flake";

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs =
    inputs@{
      self,
      nix-darwin,
      # nixpkgs,
      nixpkgs-unstable,
      nix-homebrew,
      home-manager,
      nix-vscode-extensions,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {

          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = with pkgs; [
            atomicparsley
            bats
            bitwarden-desktop
            brave
            cargo
            chafa
            cmatrix
            cowsay
            darwin.trash
            exercism
            fastfetch
            ffmpeg
            gitleaks
            iterm2
            macfuse-stubs
            mas
            meslo-lgs-nf
            mkalias
            nixfmt-rfc-style
            ocrmypdf
            # for touchid support in tmux (binary is called reattach-to-session-namespace)
            pam-reattach
            pipx
            pnpm
            shellcheck
            texinfo # to read info files
            tldr
            tree
            wget
            xcodes
            zsh-powerlevel10k
            zsh-completions
          ];

          # programs.thefuck.alias = "oh";

          environment.variables.HOMEBREW_NO_ANALYTICS = "1";

          environment.etc."pam.d/sudo_local".text = ''
            # Managed by Nix Darwin
            auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
            auth       sufficient     pam_tid.so
          '';

          fonts.packages = [ ];

          homebrew = {
            enable = true;
            taps = [
              "bell-sw/liberica" # jdk
              "buo/cask-upgrade" # brew-cask-upgrade
              "gcenx/wine" # kegworks
              "gromgit/fuse" # ntfs-3g-mac
              "homebrew/bundle"
              "jorgelbg/tap" # pinentry-touchid
              "rcmdnk/file" # brew-file
            ];
            brews = [
              "brew-file"
              "ntfs-3g-mac"
              "pinentry-touchid"
            ];
            casks = [
              "google-drive"
              {
                name = "kegworks";
                args = "no-quarantine";
              }
              "liberica-jdk21"
              "mounty"
              "masscode"
              "pdf-expert"
              "protonvpn"
              "qlmarkdown"
              "xcodes"
            ];
            masApps = {
              "Contacts Sync for Google Gmail" = 451691288;
              "CotEditor" = 1024640650;
              "Foldor" = 1559426624;
              "GarageBand" = 682658836;
              "iMovie" = 408981434;
              "Keynote" = 409183694;
              "Numbers" = 409203825;
              "Pages" = 409201541;
              "PastePal" = 1503446680;
              "Patterns" = 429449079;
              "PDF Squeezer" = 1502111349;
              "PDFgear" = 6469021132;
              "Snip" = 1527428847;
              "Sync Folders Pro" = 522706442;
              "tipitaka_pali_reader" = 1541426949;
            };
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
            # zap removes all preferences as well as the program
            # onActivation.cleanup = "zap";
          };

          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              # Set up applications.
              echo "setting up /Applications..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read src; do
                app_name=$(basename "$src")
                echo "copying $src" >&2
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';

          system.defaults = {
            dock.autohide = true;
            NSGlobalDomain.KeyRepeat = 2;
          };

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          services.mongodb = {
            package = "mongodb-ce";
            enable = true;
          };

          services.redis.enable = true;

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          nix = {
            package = pkgs.nix;
            gc.automatic = true;
            optimise.automatic = true;
            settings = {
              auto-optimise-store = true;
              experimental-features = [
                "nix-command"
                "flakes"
              ];
            };
          };

          # Create /etc/zshrc that loads the nix-darwin environment.
          programs.zsh.enable = true; # default shell on catalina
          # programs.fish.enable = true;

          # programs.zsh.promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          programs.zsh.autosuggestions.enable = true;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "x86_64-darwin";

          users.users.timotheos = {
            name = "timotheos";
            home = "/Users/timotheos";
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#MVs-MBP
      darwinConfigurations."MVs-MBP" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              # enableRosetta = true;

              # User owning the Homebrew prefix
              user = "timotheos";

              # Automatically migrate existing Homebrew installations
              autoMigrate = true;
            };
          }
          home-manager.darwinModules.home-manager
          {
            # `home-manager` config
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.timotheos = import ./home.nix;
          }
          # enable the default overlay from nix-vscode-extensions
          # to make more vscode extensions available
          { nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ]; }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."MVs-MBP".pkgs;
    };
}
