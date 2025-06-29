{ config, ... }:
{
  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  system.defaults = {
    CustomUserPreferences = {
      # set iterm2 to write user prefs to custom file
      "com.googlecode.iterm2" = {
        "com.googlecode.iterm2.PrefsCustomFolder" = "$NIXFILES/modules/iterm2";
        "com.googlecode.iterm2.LoadPrefsFromCustomFolder" = true;
      };
    };
  };

  homebrew = {
    enable = true;

    # set to false as the brew version is pinned by the nix-homebrew package
    onActivation.autoUpdate = false;

    # allow upgrading outdated formulae during system activation
    # (after updating taps with "flake update")
    onActivation.upgrade = true;

    # don't attempt to autoUpdate when running brew commands manually
    global.autoUpdate = false;

    # uninstall removes all unlisted packages, zap does a "deep uninstall", deleting all associated files including preferences
    onActivation.cleanup = "uninstall";
    # prevent onActivation.cleanup option from removing taps listed in nix-homebrew module
    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = [
      # encountering build error with nixpkgs version
      "bitwarden-cli"
      # Command-line fuzzy finder written in Go
      # "fzf"
      # "m4b-tool"
      "pinentry-touchid"
    ];
    # use the "greedy" option to always upgrade auto-updated or unversioned cask to latest version
    casks = [
      # "abbyy-finereader-pdf"
      # "adobe-digital-editions"
      "anki"
      "calibre" # Comprehensive e-book software
      # Hard disk backup and cloning utility
      {
        name = "carbon-copy-cloner";
        greedy = true;
      }
      # "cheatsheet"
      "cirrus" # Inspector for iCloud Drive folders
      # "coteditor"
      "customshortcuts" # Customise menu item keyboard shortcuts, integrates with keyclu
      "daisydisk" # Disk space visualiser

      # "discord"
      # "google-drive"
      # "isyncr"
      # iterm2 brew updates are more recent compared to the nix package
      {
        name = "iTerm2";
        greedy = true;
      }
      {
        name = "kegworks";
        args = {
          no_quarantine = true;
        };
      }
      # popup window showing application's shortcuts
      {
        name = "keyclu";
        greedy = true;
      }
      # key-codes
      "kid3"
      # Create, manage and debug system and user services
      {
        name = "launchcontrol";
        greedy = true;
      }
      {
        name = "lingon-x";
        greedy = true;
      }
      # File system integration
      {
        name = "macfuse";
        greedy = true;
      }
      # "mamp"
      # "masscode"
      # "mounty"
      # "microsoft-excel"
      # "microsoft-onenote"
      # "microsoft-powerpoint"
      # "microsoft-word"
      "musicbrainz-picard"
      {
        name = "onedrive"; # Cloud storage client
        greedy = true;
      }
      # PDF reader, editor and annotator
      {
        name = "pdf-expert";
        greedy = true;
      }
      # "plex-media-server"
      "private-internet-access"
      # "qlmarkdown"
      # Mux and tag mp4 files
      {
        name = "subler";
        greedy = true;
      }
      # Open-source BitTorrent client
      # NB: The GUI versions on nixpkgs do not work on mac
      {
        name = "transmission";
        greedy = true;
      }
      # "syncmate"
      # "tor-browser"
      # editor that supports Markdown
      {
        name = "typora";
        greedy = true;
      }
      # Create, manage, and run virtual machines
      {
        name = "vmware-fusion";
        greedy = true;
      }
      "xcodes"
      # Collect, organise, cite, and share research sources
      {
        name = "zotero";
        greedy = true;
      }
    ];
    # setting this option will add the mas cli binary to homebrew.brews
    masApps = {
      # Desktop password and login vault
      "Bitwarden" = 1352778147;
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
      "WhatsApp Messenger" = 310633997;
    };
  };
}
