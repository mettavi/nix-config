{
  config,
  lib,
  pkgs,
  ...
}:
let
  withFirefox = (
    builtins.any (config: config.mettavi.apps.firefox.enable) (
      builtins.attrValues config.home-manager.users
    )
  );
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
  lock-empty-string = {
    Value = "";
    Status = "locked";
  };
in
{
  programs.firefox = {
    enable = withFirefox;
    languagePacks = [ "en-US" ];

    # Check about:policies#documentation for options.
    policies = {
      DisableFirefoxStudies = true;
      DisableTelemetry = true;
      DisplayBookmarksToolbar = "newtab"; # alternatives: "always" or "never"
      DisplayMenuBar = "default-off"; # (click ALT to turn on temporarily) Alternatives: "always", "never", or "default-on"
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      EnableTrackingProtection = {
        Category = "strict";
        Cryptomining = true;
        EmailTracking = true;
        Fingerprinting = true;
        SuspectedFingerprinting = true;
        Value = true;
      };
      # ---- EXTENSIONS ----
      # Check about:support for extension/add-on ID strings.
      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      ExtensionUpdate = true;
      ExtensionSettings =
        let
          moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
        in
        {
          "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
          "uBlock0@raymondhill.net" = {
            install_url = moz "ublock-origin";
            installation_mode = "force_installed";
          };
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = moz "bitwarden-password-manager";
            installation_mode = "force_installed";
          };
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url = moz "privacy-badger-17";
            installation_mode = "force_installed";
          };
          "extension@tabliss.io" = {
            install_url = moz "tabliss-2.6.0.xpi";
            installation_mode = "force_installed";
          };
        };
      # Extensions settings (NB: Few extensions support this key)
      "3rdparty".Extensions = {
        "uBlock0@raymondhill.net".adminSettings = {
          userSettings = rec {
            uiTheme = "dark";
            uiAccentCustom = true;
            uiAccentCustom0 = "#8300ff";
            advancedUserEnabled = true;
            cloudStorageEnabled = lib.mkDefault true;
            largeMediaSize = 500;
            popupPanelSections = 31;

            importedLists = [
              "https:#filters.adtidy.org/extension/ublock/filters/3.txt"
              "https:#github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
            ];

            externalLists = lib.concatStringsSep "\n" importedLists;
          };

          selectedFilterLists = [
            "user-filters"
            "ublock-filters"
            "ublock-badware"
            "ublock-privacy"
            "ublock-quick-fixes"
            "ublock-unbreak"
            "easylist"
            "adguard-generic"
            "adguard-mobile"
            "easyprivacy"
            "adguard-spyware-url"
            "block-lan"
            "urlhaus-1"
            "plowe-0"
            "dpollock-0"
            "fanboy-cookiemonster"
            "ublock-cookies-easylist"
            "adguard-cookies"
            "ublock-cookies-adguard"
            "fanboy-social"
            "adguard-social"
            "fanboy-thirdparty_social"
            "easylist-chat"
            "easylist-newsletters"
            "easylist-notifications"
            "easylist-annoyances"
            "adguard-mobile-app-banners"
            "adguard-other-annoyances"
            "adguard-popup-overlays"
            "adguard-widgets"
            "ublock-annoyances"
            "https://filters.adtidy.org/extension/ublock/filters/3.txt"
          ];
        };
      };
      FirefoxHome = {
        Highlights = false;
        Pocket = false;
        Search = true;
        Snippets = false;
        SponsoredPocket = false;
        SponsoredStories = false;
        SponsoredTopSites = false;
        Stories = false;
        TopSites = true;
      };
      FirefoxSuggest = {
        ImproveSuggest = false;
        SponsoredSuggestions = false;
        WebSuggestions = false;
      };
      HardwareAcceleration = true;
      Homepage.StartPage = "previous-session";
      HttpsOnlyMode = "enabled";
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      # If the value is an empty string (“”), the first run page is not displayed.
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      PasswordManagerEnabled = false;
      PictureInPicture.Enabled = false;
      PopupBlocking.Default = true;
      # Check about:config for options.
      Preferences = {
        # Privacy settings
        "browser.contentblocking.category" = {
          Value = "strict";
          Status = "locked";
        };
        "browser.formfill.enable" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
        "browser.newtabpage.activity-stream.system.showWeather" = false;
        "browser.newtabpage.activity-stream.topSitesRows" = 2;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
        "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
        "browser.newtabpage.pinned" = lock-empty-string;
        "browser.search.suggest.enabled" = lock-false;
        "browser.search.suggest.enabled.private" = lock-false;
        "browser.tabs.firefox-view" = false;
        "browser.tabs.tabmanager.enabled" = false;
        "browser.topsites.contile.enabled" = lock-false;
        "browser.urlbar.suggest.searches" = lock-false;
        "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
        "extensions.pocket.enabled" = lock-false;
        "extensions.screenshots.disabled" = lock-true;
        "general.autoScroll" = true;
        "media.hardware-video-decoding.force-enabled" = true;
      };
      PrimaryPassword = false;
      PromptForDownloadLocation = false;
      RequestedLocales = "en-AU,en-US";
      SearchBar = "unified"; # alternative: "separate"
      SearchSuggestEnabled = true;
      ShowHomeButton = true;
      SkipTermsOfUse = true;
      TranslateEnabled = true;
      UserMessaging = {
        SkipOnboarding = true;
        UrlbarInterventions = false;
      };

    };
  };
  environment.sessionVariables = lib.mkIf config.services.displayManager.gdm.wayland {
    # for firefox to run on wayland (may be default now?)
    MOZ_ENABLE_WAYLAND = "1";
  };

  # required for screensharing functionality
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      # xdg-desktop-portal-wlr # Use this for Sway/wlroots
      xdg-desktop-portal-gtk # Use this for GNOME
      # xdg-desktop-portal-kde  # Use this for KDE
    ];
  };
}
