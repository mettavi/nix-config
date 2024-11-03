{
  pkgs,
  config,
  inputs,
  ...
}:
let
  user="timotheos";
  nixpkgs = inputs.nixpkgs.legacyPackages.${pkgs.system};
in
{

  nix = {
    # auto upgrade nix package
    package = pkgs.nix;
    gc.automatic = true;
    nixPath = [ "nixpkgs=${inputs.nixpkgs-unstable}" ];
    optimise.automatic = true;
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://toyvo.cachix.org" ];
      trusted-public-keys = [ "toyvo.cachix.org-1:s++CG1te6YaS9mjICre0Ybbya2o/S9fZIyDNGiD4UXs=" ];
      trusted-users = [ "root" ];
    };
  };

  # Auto upgrade the nix daemon service.
  services.nix-daemon.enable = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-darwin";

  nixpkgs.config.allowUnfree = true;

  users.users.timotheos = {
    name = "timotheos";
    home = "/Users/timotheos";
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

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

  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  # pam_reattach.so re-enables pam_tid.so in tmux
  environment.etc."pam.d/sudo_local".text = ''
    # Managed by Nix Darwin
    auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
    auth       sufficient     pam_tid.so
  '';

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # PACKAGES
    # atomicparsley
    # bash-completion
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
    # nixpkgs.kanata
    macfuse-stubs # Build time stubs for FUSE on macOS
    mas
    mkalias
    nixfmt-rfc-style
    nixd # nix language server
    node2nix
    ntfs3g # Read-write NTFS driver for FUSE
    ocrmypdf
    pam-reattach # for touchid support in tmux (binary "reattach-to-session-namespace")
    pinentry_mac
    # pipx
    # pnpm
    # poppler
    # python312Packages.pygobject3
    # python-launcher
    shellcheck
    # stow
    # texinfo # to read info files
    tldr
    tree
    # vulkan-headers
    wget
    # xcodes
    # zsh-powerlevel10k
    zsh-completions

    # GUI APPS
    # anki
    # appcleaner
    # bitwarden-desktop
    # brave
    # calibre
    # dbeaver-bin
    # djview
    # google-chrome
    # goldendict-ng is currently only available for linux
    # grandperspective
    # iina
    # iterm2
    # karabiner-elements
    # keka
    # obsidian
    # picard
    # transmission_4
    # vlc-bin-universal
    # zeal-qt6
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
      # "rcmdnk/file" # brew-file
    ];
    brews = [
      # "brew-file"
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
      # {
      #   name = "kegworks";
      #   args = "no-quarantine";
      # }
      # "isyncr"
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
      # "xcodes"
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

  programs = {
    bash = {
      # this will install bash-completion package
      completion.enable = true;
    };
    #   fish.enable = true;
    #   thefuck.alias = "oh";
    nh = {
      enable = true;
      # clean.enable = true;
      # Installation option once https://github.com/LnL7/nix-darwin/pull/942 is merged:
      # package = nh_darwin.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
    #   # Create /etc/zshrc that loads the nix-darwin environment.
    zsh = {
      enable = true;
      # autosuggestions.enable = true;
      # promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}
