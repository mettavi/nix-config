{
  config,
  inputs,
  lib,
  nixosConfig,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.apps.firefox;
in
{
  options.mettavi.apps.firefox = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure firefox";
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables = lib.mkIf nixosConfig.services.displayManager.gdm.wayland {
      # MOZ_ENABLE_WAYLAND = "1"; # Explicitly enables Wayland for Firefox (enabled by default)
      # NIXOS_OZONE_WL = "1"; # Forces Wayland backend for applications using Ozone
      # take advantage of more video codecs supported by a IGP/GPU, specifies the preferred rendering device
      MOZ_DRM_DEVICE = "/dev/dri/renderD128";
      # Enable xinput2 to improve touchscreen support and enable additional touchpad gestures and smooth scrolling.
      MOZ_USE_XINPUT2 = "1";
    };

    # enable the firefox-gnome-theme via a flake input (also see userChrome and userContent below)
    home.file.".mozilla/firefox/${config.programs.firefox.profiles.mettavi.name}/chrome/firefox-gnome-theme".source =
      inputs.firefox-gnome-theme;

    programs.firefox = {
      enable = true;
      languagePacks = [
        "en_AU"
        "en-US"
      ];
      nativeMessagingHosts = lib.optionals nixosConfig.services.desktopManager.gnome.enable [
        # Gnome shell native connector
        pkgs.gnome-browser-connector
      ];
      # required for screensharing under Wayland, see https://wiki.nixos.org/wiki/Firefox
      package = (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { });

      profiles = {
        "mettavi" = {
          id = 0;
          isDefault = true;
          bookmarks = {
            force = true;
            settings = [
              {
                name = "wikipedia";
                tags = [ "wiki" ];
                keyword = "wiki";
                url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
              }
            ];
          };
          # extensions = {
          #   packages = with inputs.firefox-addons.packages.${pkgs.system}; [
          #     bitwarden
          #     privacy-badger
          #     sponsorblock
          #     tabliss
          #   ];
          # };
          # extraConfig = '' ''; # user.js
          userChrome = # bash
            ''
              @import "firefox-gnome-theme/userChrome.css";
            ''; # chrome CSS
          userContent = # bash
            ''
              @import "firefox-gnome-theme/userContent.css";
            ''; # content CSS

          # ~/.mozilla/firefox/PROFILE_NAME/prefs.js | user.js
          settings = {
            ## FIREFOX GNOME THEME
            ## - https://github.com/rafaelmardojai/firefox-gnome-theme/blob/7cba78f5216403c4d2babb278ff9cc58bcb3ea66/configuration/user.js
            # (copied into here because home-manager already writes to user.js)
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # Enable customChrome.cs
            "svg.context-properties.content.enabled" = true; # Enable SVG context-propertes
            "browser.uidensity" = 0; # Set UI density to normal
            "browser.theme.dark-private-windows" = false; # Disable private window dark theme

            # ALPHABETICAL
            "app.normandy.first_run" = false;
            "app.shield.optoutstudies.enabled" = false;
            # disable updates (pretty pointless with nix)
            "app.update.channel" = "default";

            "browser.aboutConfig.showWarning" = false;
            "browser.compactmode.show" = true;
            "browser.cache.disk.enable" = false; # Be kind to hard drive
            "browser.ctrlTab.recentlyUsedOrder" = true;
            "browser.download.start_downloads_in_tmp_dir" = true;
            "browser.download.useDownloadDir" = false; # Don't ask for download dir
            "browser.download.viewableInternally.typeWasRegistered.svg" = true;
            "browser.download.viewableInternally.typeWasRegistered.webp" = true;
            "browser.download.viewableInternally.typeWasRegistered.xml" = true;
            "browser.newtabpage.pinned" = [
              {
                "label" = "GitHub";
                "url" = "https://github.com";
              }
              {
                "label" = "YouTube";
                "url" = "https://youtube.com";
              }
              {
                "label" = "YT Music";
                "url" = "https://music.youtube.com";
              }
            ];
            # Homepage settings
            # 0 = blank, 1 = home, 2 = last visited page, 3 = resume previous session
            "browser.startup.page" = 1;
            "browser.startup.homepage" = "about:home";
            "browser.search.defaultenginename" = "DuckDuckGo";
            "browser.search.order.1" = "DuckDuckGo";
            "browser.search.region" = "AU";
            "browser.search.widget.inNavBar" = true;
            "browser.search.update" = false; # allow FF to update installed search engines (eg. opensearch-based update urls)
            "browser.search.reset.enabled" = false; # Prevent reset of default search engine after FF update
            "browser.tabs.inTitlebar" = 0;
            "browser.tabs.loadInBackground" = true;
            "browser.toolbars.bookmarks.visibility" = "newtab";
            "browser.urlbar.placeholderName" = "DuckDuckGo";
            "browser.urlbar.showSearchSuggestionsFirst" = false;
            "browser.urlbar.suggest.calculator" = true; # integrated calculator
            # disable all the annoying quick actions
            "browser.urlbar.quickactions.enabled" = false;
            "browser.urlbar.quickactions.showPrefs" = false;
            "browser.urlbar.shortcuts.quickactions" = false;
            "browser.urlbar.suggest.quickactions" = false;

            "browser.contentblocking.category" = "strict"; # "standard"
            "browser.laterrun.enabled" = false;
            # whether user has seen the initial introductory message for the Enhanced Tracking Protection panel
            "browser.protections_panel.infoMessage.seen" = true;
            "browser.helperApps.deleteTempFileOnExit" = true;
            "distribution.searchplugins.defaultLocale" = "en-AU";
            "extensions.autoDisableScopes" = 0; # automatically enable extensions
            "extensions.update.enabled" = false;
            "general.autoScroll" = true;
            "general.useragent.locale" = "en-AU";

            "general.smoothScroll" = true;
            "general.smoothScroll.msdPhysics.enabled" = true;
            # Fix Firefox's smooth scrolling to have the same snappy feel as Chrome
            "general.smoothScroll.mouseWheel.durationMaxMS" = 200;
            "general.smoothScroll.mouseWheel.durationMinMS" = 100;

            # DISABLE FIREFOX ACCOUNTS
            # "identity.fxaccounts.enabled" = false;

            # Prefer dark theme
            "layout.css.prefers-color-scheme.content-override" = 0; # 0: Dark, 1: Light, 2: Auto

            "media.autoplay.default" = 5; # block both audible and inaudible media from autoplaying.
            "media.cubeb.backend" = "alsa"; # force firefox to use the ALSA/pipewire backend

            "mousewheel.default.delta_multiplier_x" = 20;
            "mousewheel.default.delta_multiplier_y" = 20;
            "mousewheel.default.delta_multiplier_z" = 20;

            # Hardens against potential credentials phishing:
            # 0 = don’t allow sub-resources to open HTTP authentication credentials dialogs
            # 1 = don’t allow cross-origin sub-resources to open HTTP authentication credentials dialogs
            # 2 = allow sub-resources to open HTTP authentication credentials dialogs (default)
            "network.auth.subresource-http-auth-allow" = 1;

            # Trusted DNS (TRR) https://wiki.mozilla.org/Trusted_Recursive_Resolver
            # 0 for off, 2 for TRR first (using DoH with a standard fallback), and 3 for TRR only (only using DoH).
            "network.trr.mode" = 2;
            "network.trr.uri" = "https://mozilla.cloudflare-dns.com/dns-query";
            "network.dns.skipTRR-when-parental-control-enabled" = false;

            # ECH - prevent TLS connections leaking request hostname
            "network.dns.echconfig.enabled" = true;
            "network.dns.http3_echconfig.enabled" = true;

            # "print.print_footerleft" = "";
            # "print.print_footerright" = "";
            # "print.print_headerleft" = "";
            # "print.print_headerright" = "";

            # VERTICAL TABS
            "sidebar.expandOnHover" = true;
            "sidebar.main.tools" = [
              "history"
              "bookmarks"
            ];
            "sidebar.revamp" = true;
            "sidebar.verticalTabs" = true;
            # Firefox 75+ remembers the last workspace it was opened on as part of its session management.
            # This is annoying, because as a result I can have a blank workspace, click Firefox from the launcher, and
            # then have Firefox open on some other workspace.
            "widget.disable-workspace-management" = true;
            "widget.use-xdg-desktop-portal.file-picker" = 1;

            # Addon recomendations
            "extensions.getAddons.showPane" = false; # disable recommendation pane in about:addons (uses Google Analytics)
            "extensions.htmlaboutaddons.recommendations.enabled" = false; # recommendations in about:addons' Extensions and Themes panes

            # Auto-decline cookies
            "cookiebanners.service.mode" = 2;
            "cookiebanners.service.mode.privateBrowsing" = 2;

            # Crash reports
            "breakpad.reportURL" = "";
            "browser.tabs.crashReporting.sendReport" = false;

            # DISABLE IRRITATING FIRST-RUN STUFF
            "browser.bookmarks.restore_default_bookmarks" = false;
            "browser.bookmarks.addedImportButton" = true;
            "browser.disableResetPrompt" = true;
            "browser.download.panel.shown" = true;
            "browser.feeds.showFirstRunUI" = false;
            "browser.messaging-system.whatsNewPanel.enabled" = false;
            "browser.rights.3.shown" = true;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.shell.defaultBrowserCheckCount" = 1;
            "browser.startup.homepage_override.mstone" = "ignore";
            "browser.uitour.enabled" = false;
            "trailhead.firstrun.didSeeAboutWelcome" = true;

            "signon.rememberSignons" = false; # Disable "save password" prompt
            "signon.autofillForms" = false;
            "signon.formlessCapture.enabled" = false;
            "dom.forms.autocomplete.formautofill" = false; # autocomplete fills forms as you type

            # DISABLE SOME TELEMETRY
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.ping-centre.telemetry" = false;
            "browser.vpn_promo.enabled" = false;
            "datareporting.healthreport.service.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "datareporting.sessions.current.clean" = true;
            "devtools.onboarding.telemetry.logged" = false;
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.coverage.opt-out" = true; # [HIDDEN PREF]
            "toolkit.coverage.opt-out" = true; # [FF64+] [HIDDEN PREF]
            "toolkit.coverage.endpoint.base" = "";
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.telemetry.hybridContent.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.prompted" = 2;
            "toolkit.telemetry.rejected" = true;
            "toolkit.telemetry.reportingpolicy.firstRun" = false;
            "toolkit.telemetry.server" = "";
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.shutdownPingSender.enabledFirstsession" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.unifiedIsOptIn" = false;
            "toolkit.telemetry.updatePing.enabled" = false;

            # As well as Firefox 'experiments'
            "experiments.activeExperiment" = false;
            "experiments.enabled" = false;
            "experiments.supported" = false;
            "network.allow-experiments" = false;

            # Disable Pocket Integration
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
            "extensions.pocket.enabled" = false;
            "extensions.pocket.api" = "";
            "extensions.pocket.oAuthConsumerKey" = "";
            "extensions.pocket.showHome" = false;
            "extensions.pocket.site" = "";

            # Force enable GPU acceleration
            "media.ffmpeg.vaapi.enabled" = true;
            "media.hardware-video-decoding.force-enabled" = true;
            "widget.dmabuf.force-enabled" = true; # Required in recent Firefoxes

            # Enable HTTPS-Only Mode
            "dom.security.https_only_mode" = true;
            "dom.security.https_only_mode_ever_enabled" = true;

            # PRIVACY/TRACKING SETTINGS
            # Prevent WebRTC leaking IP address
            "media.peerconnection.ice.default_address_only" = true;
            "privacy.donottrackheader.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.emailtracking.enabled" = true;
            "privacy.trackingprotection.cryptomining.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.pbmode.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "privacy.partition.network_state.ocsp_cache" = true;
            "privacy.firstparty.isolate" = true;
            # URL query tracking
            "privacy.query_stripping.enabled" = true;
            "privacy.query_stripping.enabled.pbmode" = true;

            # Fingerprinting
            "privacy.fingerprintingProtection" = true;
            "privacy.resistFingerprinting" = true;
            "privacy.resistFingerprinting.pbmode" = true;

            # disable using the OS's geolocation service
            "geo.provider.use_gpsd" = false;
            "geo.provider.use_geoclue" = false;

            # DISABLE CRAPPY HOME ACTIVITY STREAM PAGE
            "browser.newtab.preload" = false;
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
            "browser.newtabpage.blocked" = lib.genAttrs [
              # Facebook
              "4gPpjkxgZzXPVtuEoAL9Ig=="
              # Amazon
              "K00ILysCaEq8+bEqV/3nuw=="
              # Twitter
              "T9nJot5PurhJSy8n038xGA=="
            ] (_: 1);

          };
          search = {
            # force replace the existing search configuration. This is recommended since Firefox will
            # replace the symlink for the search configuration on every launch
            force = true; # Firefox often replaces the symlink, so force on update
            default = "ddg"; # DuckDuckGo
            privateDefault = "ddg"; # DuckDuckGo
            engines = {
              home-manager = {
                name = "hm Options";
                urls = [ { template = "https://home-manager-options.extranix.com/?query={searchTerms}"; } ];
                iconMapObj."16" = "https://home-manager-options.extranix.com/images/favicon.png";
                definedAliases = [ "@hm" ];
              };
              nix-options = {
                name = "Nix Options";
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@no" ];
              };
              nix-packages = {
                name = "Nix Packages";
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
              };
              nixos-wiki = {
                name = "NixOS Wiki";
                urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
                iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
                definedAliases = [ "@nw" ];
              };
              # builtin search engines
              google.metaData.alias = "@g"; # builtin engines only support specifying one additional alias
              bing.metaData.hidden = true;
              ebay.metaData.hidden = true;
            };
            order = [
              "ddg"
              "google"
              "nix-packages"
              "nix-options"
              "home-manager"
              "nixos-wiki"
            ];
          };
        };
      };
      policies = {
        ExtensionSettings =
          with builtins;
          let
            extension = shortId: uuid: {
              name = uuid;
              value = {
                install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
                installation_mode = "force_installed";
                updates_disabled = true;
              };
            };
          in
          listToAttrs [
            (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
            (extension "privacy-badger17" "jid1-MnnxcxisBPnSXQ@jetpack")
            (extension "sponsorblock" "sponsorBlocker@ajay.app")
            (extension "tabliss" "extension@tabliss.io")
            (extension "ublock-origin" "uBlock0@raymondhill.net")
          ];

        # "*".installation_mode = "force_installed";

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
      };
    };
  };
}
