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

  # place custom packages in one directory for ease of reference
  # each individual package is further defined in ../myPkgs/default.nx
  mypkgs = (pkgs.callPackage ../mypkgs { });

in
{
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

  # install global npm packages that are not available in nixpkgs repo
  nixpkgs.overlays = [
    (final: prev: {
      npmGlobals = final.callPackage ../npm_globals/node-packages-v18.nix {
        nodeEnv = final.callPackage ../npm_globals/node-env.nix {
          libtool = if final.stdenv.isDarwin then final.darwin.cctools else null;
        };
      };
    })
  ];

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

    extraActivation.text = ''
      if [[ ! -d /Applications/.Karabiner-VirtualHIDDevice-Manager.app ]]; then
        sudo installer -pkg "${mypkgs.karabiner-driverkit}/Karabiner-DriverKit-VirtualHIDDevice-5.0.0.pkg" -target /
        "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" activate
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
    nix-prefetch # Prefetch any fetcher function call, e.g. package sources
    node2nix # Generate Nix expressions to build NPM packages
    ntfs3g # Read-write NTFS driver for FUSE
    ocrmypdf
    pam-reattach # for touchid support in tmux (binary "reattach-to-session-namespace")
    pinentry_mac
    # pipx
    # pnpm
    # poppler
    # python-launcher
    ruby
    rustc
    shellcheck
    # stow
    # texinfo # to read info files
    tldr
    tree
    wget
    xcodes
    # TODO: Bug with statusd dependency is fixed, switch branches when merge to master on 3/12/2024 hits nixpkgs-unstable
    # zsh-powerlevel10k
    zsh-completions

    # CUSTOM APPS
    mypkgs.karabiner-driverkit

    # Install global npm packages not available in nixpkgs repo
    # using node2nix and overlay (see above)
    # npmGlobals.functional-javascript-workshop 
    # npmGlobals.how-to-markdown
    # npmGlobals.javascripting
    # npmGlobals.js-best-practices
    npmGlobals.learnyoubash
    # npmGlobals.regex-adventure
    # npmGlobals.zeal-user-contrib

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

    # autoupdate unnecessary as the brew version is pinned by the nix-homebrew package
    # onActivation.autoUpdate = true;

    # allow upgrading outdated formulae during system activation 
    # (after running "brew update", see global.autoupdate below)
    onActivation.upgrade = true;

    # installed formulae will only be upgraded after running "brew update" (and then "darwin-rebuild"), 
    # but not other brew commands
    global.autoUpdate = false;

    # uninstall removes formulae, zap removes formulae and casks
    onActivation.cleanup = "zap";
    # explicitly list taps to prevent "zap" option from attempting to untap them
    taps = [
      "homebrew/cask"
      "gcenx/wine"
    ];
    brews = [
      # install with brew as the build is currently broken on nix-darwin
      "kanata"
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
    karabiner-daemon = {
      serviceConfig = {
        Label = "com.mettavihari.karabiner-daemon";
        ProcessType = "Interactive";
        Program = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/Library/Logs/karabiner-driverkit/driverkit.out.log";
        StandardErrorPath = "/Library/Logs/karabiner-driverkit/driverkit.err.log";
      };
    };
  };

  launchd.daemons = {
    kanata = {
      serviceConfig = {
        Label = "com.mettavihari.kanata";
        ProgramArguments = [
          "/usr/local/bin/kanata"
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
      # TODO: Issue 358116 is resolved, switch branches when merge into master on 3/12/2024 hits nixpkgs-unstable
      # See https://github.com/NixOS/nixpkgs/issues/358116
      # promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}
