{
  pkgs,
  config,
  inputs,
  ...
}:
{
  networking.hostName = "mack";

  nix = {
    # auto upgrade nix package
    package = pkgs.nix;
    gc.automatic = true;
    # this ensures $NIX_PATH is set to an immutable location in the nix-store
    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
      "darwin=${inputs.nix-darwin}"
      "home-manager=${inputs.home-manager}"
    ];
    optimise.automatic = true;
    settings = {
      # this setting is deprected, see https://bit.ly/3Cp2vYB
      # auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # substituters are always enabled, trusted-substituters can be enabled on demand by untrusted users
      substituters = [
        "https://nixpkgs.cachix.org"
        "https://nix-community.cachix.org"
        "https://cachix.cachix.org"
        "https://yazi.cachix.org"
        "https://mettavi.cachix.org"
      ];
      trusted-public-keys = [
        "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
        "mettavi.cachix.org-1:rYvLGZOMT4z4hK7u5pzrbt8svJ/2JcUA/PTa1bQx4FU="
      ];
      trusted-users = [ "root" ];
    };
  };

  imports = [
    ../../common/shared/default.nix
    ../../common/darwin/default.nix
    ../../modules/sops/sops-system.nix
    # ../../overlays
  ];

  # Auto upgrade the nix daemon service.
  services.nix-daemon.enable = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-darwin";

  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowBroken = true;

  # there is also a overlays submodule included in the imports list
  nixpkgs.overlays = [
    (final: prev: {
      # install global npm packages that are not available in nixpkgs repo
      npmGlobals = final.callPackage ../../modules/npm_globals/node-packages-v18.nix {
        nodeEnv = final.callPackage ../../modules/npm_globals/node-env.nix {
          libtool = if final.stdenv.isDarwin then final.darwin.cctools else null;
        };
      };
    })
  ];

  ########### CONFIGURE SYSTEM USERS ############

  users.users.ta = rec {
    name = "timotheos";
    home = "/Users/${name}";
    # authorize remote login to host using personal ssh key
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../modules/secrets/timotheos/keys/id_ed25519.pub)
    ];
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # install GUI apps with alias instead of symlink to show up in spotlight search
  system.activationScripts = {
    applications.text =
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
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
      '';

    extraActivation.text = ''
      # Enable remote login for the host (macos ssh server)
      # WORKAROUND: `systemsetup -f -setremotelogin on` requires `Full Disk Access`
      # permission for the Application calling it
      if [[ "$(systemsetup -getremotelogin | sed 's/Remote Login: //')" == "Off" ]]; then
        launchctl load -w /System/Library/LaunchDaemons/ssh.plist
      fi
    '';

    postUserActivation.text = ''
      # avoid a login/reboot to apply new settings after system activation (macOS)
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };

  system.defaults = {
    dock.autohide = true;
    NSGlobalDomain.KeyRepeat = 2;
    CustomUserPreferences = {
      # set iterm2 to write user prefs to custom file
      "com.googlecode.iterm2" = {
        "com.googlecode.iterm2.PrefsCustomFolder" = "$DOTFILES/modules/iterm2";
        "com.googlecode.iterm2.LoadPrefsFromCustomFolder" = true;
      };
    };
  };

  # List of directories to be symlinked in /run/current-system/sw
  environment.pathsToLink = [
    "/libexec"
    "/share/doc"
    "/share/zsh"
    "/share/man"
    "/share/bash-completion"
  ];

  # pam_reattach.so re-enables pam_tid.so in tmux
  environment.etc."pam.d/sudo_local".text = ''
    # Managed by Nix Darwin
    auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
    auth       sufficient     pam_tid.so
  '';

  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];

  services = {
    #   postgresql = {
    #     enable = true;
    #     dataDir = /usr/local/var/postgres;
    #   };
    #   redis = {
    #     enable = true;
    #   };
  };

  # launchd.user.agents = {
  # mongodb = {
  #   serviceConfig = {
  #     # only start the service on demand
  #     KeepAlive = false;
  #     RunAtLoad = false;
  #   };
  # };
  #   postgresql = {
  #     serviceConfig = {
  #       # only start the service on demand
  #       KeepAlive = false;
  #       RunAtLoad = false;
  #     };
  # };
  # };

  # NB: The daemon is not used in version 3.1.0 of karabiner-driverkit
  # launchd.daemons = {
  #   karabiner-daemon = {
  #     serviceConfig = {
  #       Label = "com.mettavihari.karabiner-daemon";
  #       ProcessType = "Interactive";
  #       Program = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
  #       RunAtLoad = true;
  #       KeepAlive = true;
  #       StandardOutPath = "/Library/Logs/karabiner-driverkit/driverkit.out.log";
  #       StandardErrorPath = "/Library/Logs/karabiner-driverkit/driverkit.err.log";
  #     };
  #   };
  # };

  launchd.daemons = {
    kanata = {
      serviceConfig = {
        Label = "com.mettavihari.kanata";
        ProgramArguments = [
          "/usr/local/bin/kanata"
          "-c"
          "${config.users.users.ta.home}/.dotfiles/modules/kanata/kanata.lsp"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/Library/Logs/Kanata/kanata.out.log";
        StandardErrorPath = "/Library/Logs/Kanata/kanata.err.log";
      };
    };
  };

  programs = {
    bash = {
      # this will enable and install bash-completion package (bash.enableCompletion is deprecated)
      completion.enable = true;
    };
    #   fish.enable = true;
    # Create /etc/zshrc that loads the nix-darwin environment.
    zsh = {
      enable = true;
      promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}
