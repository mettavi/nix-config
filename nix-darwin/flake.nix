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
      nixpkgs,
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
            cargo
            chafa
            cmatrix
            cowsay
            exercism
            fastfetch
            gitleaks
            mas
            mkalias
            nixfmt-rfc-style
            ocrmypdf
            # for touchid support in tmux (binary is called reattach-to-session-namespace)
            pam-reattach
            pipx
            pnpm
            zsh-powerlevel10k
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
            brews = [ ];
            casks = [ ];
            masApps = {
              "Snip" = 1527428847;
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

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Create /etc/zshrc that loads the nix-darwin environment.
          programs.zsh.enable = true; # default shell on catalina
          # programs.fish.enable = true;

          # programs.zsh.promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

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
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."MVs-MBP".pkgs;
    };
}
