{
  pkgs,
  config,
  inputs,
  ...
}:
let
  user = "timotheos";

  # this will point to the stable nixpkgs channel rather than the default one
  # use "nixpkgs.package_name" to install a non-default package
  # nixpkgs = inputs.nixpkgs.legacyPackages.${pkgs.system};

  # define kanata as a custom local derivation
  kanata = (pkgs.callPackage ../kanata/kbin.nix { });
in
{
  # use imports block to prevent error caused by duplicated environment.systemPackages variables
  imports = [
    # install custom packages
    (
      { pkgs, ... }:
      {
        environment.systemPackages = [
          kanata # install binary directly from GH repo
        ];
      }
    )
  ];
  nix = {
    # auto upgrade nix package
    package = pkgs.nix;
    gc.automatic = true;
    nixPath = [ "nixpkgs=${inputs.nixpkgs-unstable}" ];
    optimise.automatic = true;
    settings = {
      # this setting is deprected, see https://bit.ly/3Cp2vYB
      # auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://toyvo.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "toyvo.cachix.org-1:s++CG1te6YaS9mjICre0Ybbya2o/S9fZIyDNGiD4UXs="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ "root" ];
    };
  };

  # Auto upgrade the nix daemon service.
  services.nix-daemon.enable = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-darwin";

  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowBroken = true;

  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
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
        "com.googlecode.iterm2.PrefsCustomFolder" = "$DOTFILES/iterm2";
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

  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  # pam_reattach.so re-enables pam_tid.so in tmux
  environment.etc."pam.d/sudo_local".text = ''
    # Managed by Nix Darwin
    auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
    auth       sufficient     pam_tid.so
  '';

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  # install standard packages
  environment.systemPackages = with pkgs; [
    # PACKAGES
    # atomicparsley
    bats
    # bento4
    cargo
    chafa
    # cmake
    cmatrix
    coreutils-prefixed
    cowsay
    darwin.trash
    exercism
    fastfetch
    ffmpeg
    gitleaks
    macfuse-stubs # Build time stubs for FUSE on macOS
    mas
    mkalias
    nixfmt-rfc-style
    nixd # nix language server
    nix-init # Generate Nix packages from URLs
    node2nix # Generate Nix expressions to build NPM packages
    ntfs3g # Read-write NTFS driver for FUSE
    ocrmypdf
    pam-reattach # for touchid support in tmux (binary "reattach-to-session-namespace")
    pinentry_mac
    # pipx
    # pnpm
    # poppler
    # python-launcher
    shellcheck
    # stow
    # texinfo # to read info files
    tldr
    tree
    wget
    xcodes
    zsh-powerlevel10k
    zsh-completions

    # GUI APPS
    # anki
    # appcleaner
    # bitwarden-desktop
    # brave
    # dbeaver-bin
    # djview
    # google-chrome
    # goldendict-ng is currently only available for linux
    # grandperspective
    # iina
    # iterm2
    # karabiner-elements
    keycastr # keystroke visualiser
    # keka
    # obsidian
    # picard
    # transmission_4
    # vlc-bin-universal
    # nixpkgs.zeal
    # zoom-us
  ];

  fonts.packages = with pkgs; [
    meslo-lgs-nf
    (nerdfonts.override {
      fonts = [
        "Meslo"
      ];
    })
  ];

  homebrew = {
    enable = true;
    taps = [
      # "buo/cask-upgrade" # brew-cask-upgrade
      # "gcenx/wine" # kegworks
      # "homebrew/bundle"
      "jorgelbg/tap" # pinentry-touchid
    ];
    brews = [
      "pinentry-touchid"
    ];
    casks = [
      # "abbyy-finereader-pdf"
      # "adobe-digital-editions"
      # "carbon-copy-cloner"
      # "cheatsheet"
      # "coteditor"
      # "discord"
      # "google-drive"
      {
        name = "kegworks";
        args = {
          no_quarantine = true;
        };
      }
      # "isyncr"
      # iterm2 brew updates are more recent compared to the nix package
      "iTerm2"
      # key-codes
      # "kid3"
      # "mamp"
      # "masscode"
      # "mounty"
      # "microsoft-excel"
      # "microsoft-onenote"
      # "microsoft-powerpoint"
      # "microsoft-word"
      # "pdf-expert"
      # "plex-media-server"
      # "protonvpn"
      # "qlmarkdown"
      # "syncmate"
      # "tor-browser"
      # "typora"
      # "vmware-fusion"
      "xcodes"
      # "zotero"
    ];
    masApps = {
      # "Contacts Sync for Google Gmail" = 451691288;
      # "Foldor" = 1559426624;
      # "GarageBand" = 682658836;
      # "iMovie" = 408981434;
      # "Keynote" = 409183694;
      # "Numbers" = 409203825;
      # "Pages" = 409201541;
      # "PastePal" = 1503446680;
      # "Patterns" = 429449079;
      # "PDF Squeezer" = 1502111349;
      # "PDFgear" = 6469021132;
      # "Snip" = 1527428847;
      # "Sync Folders Pro" = 522706442;
      # "tipitaka_pali_reader" = 1541426949;
    };
    # autoupdate unnecessary as the brew version is pinned by the nix-homebrew package
    # onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    # uninstall removes formulae, zap removes formulae and casks
    # onActivation.cleanup = "uninstall";
  };

  services = {
    #   postgresql = {
    #     enable = true;
    #     dataDir = /usr/local/var/postgres;
    #   };
    #   redis = {
    #     enable = true;
    #   };
  };

  launchd.user.agents = {
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
  };

  launchd.daemons = {
    kanata = {
      serviceConfig = {
        Label = "com.mettavihari.kanata";
        ProgramArguments = [
          "/run/current-system/sw/bin/kanata"
          "-c"
          "/Users/${user}/.dotfiles/kanata/kanata.lsp"
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
    nh = {
      enable = true;
      # clean.enable = true;
      # Installation option once https://github.com/LnL7/nix-darwin/pull/942 is merged:
      # package = nh_darwin.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
    # Create /etc/zshrc that loads the nix-darwin environment.
    zsh = {
      enable = true;
      promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}
