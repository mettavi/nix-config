{
  pkgs,
  config,
  inputs,
  ...
}:
{

  nix = {
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
    # bats
    cargo
    # chafa
    cmatrix
    cowsay
    # darwin.trash
    # exercism
    fastfetch
    # ffmpeg
    # gitleaks
    # macfuse-stubs
    # mas
    # meslo-lgs-nf
    mkalias
    nixfmt-rfc-style
    nixd # nix language server
    node2nix
    # ocrmypdf
    pam-reattach # for touchid support in tmux (binary "reattach-to-session-namespace")
    # pipx
    # pnpm
    # shellcheck
    # texinfo # to read info files
    # tldr
    # tree
    # wget
    # xcodes
    # zsh-powerlevel10k
    # zsh-completions

    # GUI APPS
    # anki
    # appcleaner
    # bitwarden-desktop
    # brave
    # calibre
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

  fonts.packages = [ ];

  homebrew = {
    enable = true;
    taps = [
      # "bell-sw/liberica" # jdk
      # "buo/cask-upgrade" # brew-cask-upgrade
      # "gcenx/wine" # kegworks
      # "gromgit/fuse" # ntfs-3g-mac
      # "homebrew/bundle"
      # "jorgelbg/tap" # pinentry-touchid
      # "rcmdnk/file" # brew-file
    ];
    brews = [
      # "brew-file"
      # "ntfs-3g-mac"
      # "pinentry-touchid"
    ];
    casks = [
      # "abbyy-finereader-pdf"
      # "adobe-digital-editions"
      # "carbon-copy-cloner"
      # "coteditor"
      # "google-drive"
      # {
      #   name = "kegworks";
      #   args = "no-quarantine";
      # }
      # "isyncr"
      # "kid3"
      # "liberica-jdk21"
      # "mounty"
      # "masscode"
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
      "Snip" = 1527428847;
      # "Sync Folders Pro" = 522706442;
      # "tipitaka_pali_reader" = 1541426949;
    };
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    # zap removes all preferences as well as the program
    # onActivation.cleanup = "zap";
  };

  services = {
    #   mongodb = {
    #     enable = true;
    #     package = "mongodb-ce-6_0";
    #   };
    #   postgresql = {
    #     enable = true;
    #     dataDir = /usr/local/var/postgres;
    #   };
    #   redis = {
    #     enable = true;
    #   };
  };

  launchd.user.agents = {
    #   postgresql = {
    #     serviceConfig = {
    #       # only start the service on demand
    #       KeepAlive = false;
    #       RunAtLoad = false;
    #     };
    # };
    # mongodb = {
    #   serviceConfig = {
    #     # only start the service on demand
    #     KeepAlive = false;
    #     RunAtLoad = false;
    #   };
    # };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # programs.zsh.promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  # programs.zsh.autosuggestions.enable = true;

  # programs.thefuck.alias = "oh";

}
