{
  pkgs,
  config,
  inputs,
  system,
  user,
  ...
}:
let
  # this will point to a stable nixpkgs input rather than the default one
  # use "nixpkgs_name.package_name" to install a non-default package
  # nixpkgs-24_11 = inputs.nixpkgs-24_11.legacyPackages.${system};
  # nixpkgs-24_05 = inputs.nixpkgs-24_05.legacyPackages.${system};

  nh_beta = inputs.nh.packages.${system}.nh;

  # to prevent "make: *** No rule to make target 'install'.  Stop." error (missing install phase)
  zeal_mac = pkgs.zeal-qt6.overrideAttrs (oldAttrs: {
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications"
      cp -r *.app "$out/Applications"

      runHook postInstall
    '';
  });

  # place custom packages in one directory for ease of reference
  # each individual package is further defined in ../mypkgs/default.nx
  mypkgs = (pkgs.callPackage ../mypkgs { });

in
{
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
    inputs.sops-nix.darwinModules.sops
    ./overlays
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    # If you use something different from YAML, you can also specify it here:
    #sops.defaultSopsFormat = "yaml";
    age = {
      # automatically import host SSH keys as age keys
      # NB: ssh host keys can be generated with the "ssh-keygen -A" command
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      # This will generate a new key if the key specified above does not exist
      generateKey = true;
    };
    gnupg.sshKeyPaths = [ ];
    # secrets will be output to /run/secrets
    # e.g. /run/secrets/msmtp-password
    # secrets required for user creation are handled in respective ./users/<username>.nix files
    # because they will be output to /run/secrets-for-users and only when the user is assigned to a host.
    secrets = {
      # For home-manager a separate age key is used to decrypt secrets and must be placed onto the host. This is because
      # the user doesn't have read permission for the ssh service private key. However, we can bootstrap the age key from
      # the secrets decrypted by the host key, which allows home-manager secrets to work without manually copying over
      # the age key.
      # These age keys are unique for the user on each host and are generated on their own (i.e. they are not derived
      # from an ssh key).
      github_token = {
        owner = "${user}";
      };
      CACHIX_AUTH_TOKEN = {
      owner = "${user}";
    };
      "private-keys/timotheos" = {
      owner = "${user}";
    };
  };

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
        sudo installer -pkg "${mypkgs.karabiner-driverkit}/Karabiner-DriverKit-VirtualHIDDevice-3.1.0.pkg" -target /
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
    age # Modern encryption tool with small explicit keys
    # atomicparsley
    bats
    # bento4
    cachix
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
    nix-fast-build # speed-up your evaluation and building process
    nixfmt-rfc-style
    nixd # nix language server
    nix-init # Generate Nix packages from URLs
    node2nix # Generate Nix expressions to build NPM packages
    ntfs3g # Read-write NTFS driver for FUSE
    nurl # generate Nix fetcher calls from repository URLs
    ocrmypdf
    pam-reattach # for touchid support in tmux (binary "reattach-to-session-namespace")
    pinentry_mac
    pinentry-tty # Passphrase entry dialog utilizing the Assuan protocol
    # pipx
    # pnpm
    # poppler
    # python-launcher
    ruby
    rustc
    shellcheck
    sops # Simple and flexible tool for managing secrets
    # stow
    # texinfo # to read info files
    tldr
    tree
    wget
    xcodes
    zsh-completions
    zsh-powerlevel10k

    # "PINNED" APPS
    nh_beta

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

    # getting error "cannot download WhatsApp.app from any mirror"
    # fix was committed to master on Wed 18 Dec, see https://github.com/NixOS/nixpkgs/pull/365792/commits
    # whatsapp-for-mac
    zeal_mac
    # zoom-us
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
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
    # taps cannot be uninstalled here, they are managed by homebrew.nix
    taps = [
      "homebrew/cask"
      "gcenx/wine"
      "jorgelbg/tap"
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
      # "lingon-x"
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
    # Create /etc/zshrc that loads the nix-darwin environment.
    zsh = {
      enable = true;
      promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}
