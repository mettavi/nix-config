{
  config,
  inputs,
  lib,
  pkgs,
  secrets_path,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.profiles.dailydriver;
  emailSecrets.sopsFile = "${secrets_path}/secrets/apps/email.yaml";
in
{
  options.mettavi.profiles.dailydriver = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "A profile for my daily driver (currently a macbookpro)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      with pkgs.xpkgs;
      [
        karere # Gtk4 WhatsApp client
        kdePackages.okular # KDE document viewer
        mpv # General-purpose media player, fork of MPlayer and mplayer2
        pdfarranger # python-gtk application to merge/split/rotate/crop/rearrange PDFs
        picard # offical musicbrainz tagger
        variety # wallpaper manager
        # localsend # Open source cross-platform alternative to AirDrop
        zoom-us # video conferencing applications
      ]
      ++
        # Install global npm packages not available in nixpkgs repo
        # using node2nix and overlay (see above)
        [
          # npmGlobals.functional-javascript-workshop
          # npmGlobals.how-to-markdown
          # npmGlobals.javascripting
          # npmGlobals.js-best-practices
          # npmGlobals.learnyoubash
          # npmGlobals.regex-adventure
          # npmGlobals.zeal-user-contrib
        ];
    mettavi.system = {
      shell = {
        kanata.enable = true;
      };
    };

    # Force override the global UTC default to let systemd handle it dynamically
    time.timeZone = lib.mkForce null;
    # Enable the dynamic tracking daemon
    services.automatic-timezoned.enable = true;
    services.geoclue2 = {
      geoProviderUrl = "https://api.beacondb.net/v1/geolocate";
      # Allow the system daemon to read surrounding Wi-Fi signals
      enableWifi = true;
      # Optional: Submit data back to beaconDB to build out regional maps
      # (Requires a working GPS antenna if true, change to false if you lack one)
      submitData = false;
    };

    home-manager.users.${username} = {
      home = {
        packages = with pkgs; [
          goldendict-ng # Advanced multi-dictionary lookup program
          poppler-utils # PDF rendering library tools
          linpkgs.tipitaka_pali_reader
        ];
        sessionVariables = {
          # required for electron apps, which don't read the mimeapps.list file
          DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
        };
      };
      mettavi = {
        apps = {
          anki.enable = true;
          firefox.enable = true;
          ghostty.enable = true;
          latex.enable = true;
          obsidian.enable = true;
          thunderbird =
            let
              burner = inputs.secrets.email.burner;
              monk = inputs.secrets.email.monk;
              personal = inputs.secrets.email.personal;
              # NB: 1. leave "accountFilters" unassigned in extraEmailAccounts to use all filters
              # 2. the default "flavor" is "gmail.com"
            in
            {
              enable = true;
              accountsOrder = [
                personal
                monk
                burner
              ];
              extraEmailAccounts = {
                ${monk} = {
                  accountFilters = [
                    "tagGH"
                  ];
                  address = monk;
                  aliases = [ personal ];
                };
                ${burner} = {
                  accountFilters = [
                  ];
                  address = burner;
                };
              };
            };
          zotero.enable = true;
        };
        shell = {
          bash.enable = true;
          nh.enable = true;
          nvim-wrap.enable = true;
          tmux.enable = true;
          yazi.enable = true;
        };
      };
      # define sops secrets for email accounts used specifically on my daily system
      sops.secrets = {
        "users/${username}/email/${inputs.secrets.email.burner}" = emailSecrets;
      };
      xdg.autostart = {
        enable = true;
        entries = [
          "${pkgs.variety}/share/applications/variety.desktop"
        ];
      };
    };
  };
}
