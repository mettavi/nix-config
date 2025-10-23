{
  config,
  inputs,
  lib,
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
    programs.firefox = {
      enable = true;
      profiles = {
        "mettavi" = {
          id = 0;
          name = "default";
          isDefault = true;
          bookmarks = [
            {
              name = "wikipedia";
              tags = [ "wiki" ];
              keyword = "wiki";
              url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
            }
          ];
          extensions = {
            packages = with inputs.firefox-addons.packages.${pkgs.system}; [
              bitwarden
              sponsorblock
            ];
          };
          settings = {
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
            # "browser.startup.homepage" = "https://duckduckgo.com";
            "browser.startup.homepage" = "about:home";
            "browser.search.defaultenginename" = "DuckDuckGo";
            "browser.search.order.1" = "DuckDuckGo";
            "browser.search.region" = "PL";
            "browser.search.widget.inNavBar" = true;
            "browser.tabs.inTitlebar" = 0;
            "browser.tabs.loadInBackground" = true;
            "browser.toolbars.bookmarks.visibility" = "newtab";
            "browser.urlbar.placeholderName" = "DuckDuckGo";
            "browser.urlbar.showSearchSuggestionsFirst" = false;
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
            "general.autoScroll" = true;
            "general.useragent.locale" = "en-AU";

            # DISABLE FIREFOX ACCOUNTS
            # "identity.fxaccounts.enabled" = false;

            "mousewheel.default.delta_multiplier_x" = 20;
            "mousewheel.default.delta_multiplier_y" = 20;
            "mousewheel.default.delta_multiplier_z" = 20;

            # "print.print_footerleft" = "";
            # "print.print_footerright" = "";
            # "print.print_headerleft" = "";
            # "print.print_headerright" = "";

            # VERTICAL TABS
            "sidebar.verticalTabs" = true;
            "sidebar.revamp" = true;
            "sidebar.main.tools" = [
              "history"
              "bookmarks"
            ];
            "signon.rememberSignons" = false; # Disable "save password" prompt
            # Firefox 75+ remembers the last workspace it was opened on as part of its session management.
            # This is annoying, because I can have a blank workspace, click Firefox from the launcher, and
            # then have Firefox open on some other workspace.
            "widget.disable-workspace-management" = true;
            "widget.use-xdg-desktop-portal.file-picker" = 1;

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

            # DISABLE SOME TELEMETRY
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.ping-centre.telemetry" = false;
            "datareporting.healthreport.service.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "datareporting.sessions.current.clean" = true;
            "devtools.onboarding.telemetry.logged" = false;
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.telemetry.hybridContent.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.prompted" = 2;
            "toolkit.telemetry.rejected" = true;
            "toolkit.telemetry.reportingpolicy.firstRun" = false;
            "toolkit.telemetry.server" = "";
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.unifiedIsOptIn" = false;
            "toolkit.telemetry.updatePing.enabled" = false;

            # Force enable GPU acceleration
            "media.ffmpeg.vaapi.enabled" = true;
            "media.hardware-video-decoding.force-enabled" = true;
            "widget.dmabuf.force-enabled" = true; # Required in recent Firefoxes

            # Enable HTTPS-Only Mode
            "dom.security.https_only_mode" = true;
            "dom.security.https_only_mode_ever_enabled" = true;

            # Privacy settings
            "privacy.donottrackheader.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
            "privacy.partition.network_state.ocsp_cache" = true;
            # DISABLE CRAPPY HOME ACTIVITY STREAM PAGE
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
            force = true;
            default = "ddg"; # DuckDuckGo
            engines = {
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
            };

            home-manager = {
              name = "hm Options";
              urls = [ { template = "https://home-manager-options.extranix.com/?query={searchTerms}"; } ];
              iconMapObj."16" = "https://home-manager-options.extranix.com/images/favicon.png";
              definedAliases = [ "@hm" ];
            };

            nixos-wiki = {
              name = "NixOS Wiki";
              urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
              iconMapObj."16" = "https://wiki.nixos.org/favicon.ico";
              definedAliases = [ "@nw" ];
            };

            bing.metaData.hidden = true; # hide the bing search engine
            google.metaData.alias = "@g"; # builtin engines only support specifying one additional alias
          };
          order = [
            "ddg"
            "google"
            "nix-packages"
            "nix-options"
            "nixos-wiki"
            "home-manager"
          ];
          privateDefault = "ddg"; # DuckDuckGo
        };
      };
    };
  };
}
