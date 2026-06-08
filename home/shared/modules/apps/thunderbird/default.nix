# Code adapted with thanks from:
# https://github.com/khaneliman/khanelinix/blob/0bff25ee02bc35540093118bff7106b460b9aad8/modules/home/programs/graphical/apps/thunderbird/default.nix
{
  config,
  inputs,
  lib,
  mylib,
  secrets_path,
  ...
}:
with lib;
let
  inherit (lib) mkIf;
  inherit (mylib.module) mkOpt;
  cfg = config.mettavi.apps.thunderbird;
  username = config.home.username;
  emailSecrets.sopsFile = "${secrets_path}/secrets/apps/email.yaml";
in
{
  options.mettavi.apps.thunderbird = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure the email client thunderbird";
    };
    theme = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Thunderbird theme palette";
          isDark = mkOpt lib.types.bool true "Whether the Thunderbird theme uses dark chrome.";
          colors = {
            bg = mkOpt (lib.types.nullOr lib.types.str) null "Main Thunderbird background color.";
            surface = mkOpt (lib.types.nullOr lib.types.str) null "Toolbar and sidebar surface color.";
            surfaceAlt = mkOpt (lib.types.nullOr lib.types.str) null "Raised control surface color.";
            fg = mkOpt (lib.types.nullOr lib.types.str) null "Primary Thunderbird foreground color.";
            accent = mkOpt (lib.types.nullOr lib.types.str) null "Selection and active accent color.";
            accentSoft = mkOpt (lib.types.nullOr lib.types.str) null "Secondary accent color.";
            accentFg =
              mkOpt (lib.types.nullOr lib.types.str) null
                "Foreground color used on accent backgrounds.";
            border = mkOpt (lib.types.nullOr lib.types.str) null "Border and separator color.";
          };
        };
      };
      default = { };
      description = "Theme palette used to generate Thunderbird chrome CSS.";
    };
    accountsOrder = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Custom ordering of accounts.";
    };
    extraCalendarAccounts = lib.mkOption {
      type =
        let
          accountType = lib.types.submodule {
            options = {
              url = mkOpt lib.types.str null "Calendar url";
              type = mkOpt (lib.types.enum [
                "caldav"
                "http"
              ]) null "Calendar flavor";
              color = mkOpt lib.types.str null "color";
            };
          };
        in
        lib.types.attrsOf accountType;
      default = {
        "Australian Holidays" = {
          # or use the public ical address?
          url = "https://apidata.googleusercontent.com/caldav/v2/en.australian#holiday@group.v.calendar.google.com/events/";
          type = "caldav";
          color = "#92cfe1";
        };
        "Uposatha Moondays" = {
          # or use the public ical address?
          url = "https://apidata.googleusercontent.com/caldav/v2/od6acogo4ggp07rpj17km08kdddutj8u@import.calendar.google.com/events/";
          type = "caldav";
          color = "#92cfe1";
        };
        "Green Bay Packers" = {
          url = "https://sports.yahoo.com/nfl/teams/gnb/ical.ics";
          type = "http";
          color = "#F9BC12";
        };
      };
      description = "Extra calendar accounts to configure.";
    };
    extraContactsAccounts = lib.mkOption {
      type =
        let
          accountType = lib.types.submodule {
            options = {
              url = mkOpt lib.types.str null "Contacts url";
              type = mkOpt (lib.types.enum [
                "carddav"
                "http"
                "google_contacts"
              ]) null "Contacts flavor";
              color = mkOpt lib.types.str null "color";
            };
          };
        in
        lib.types.attrsOf accountType;
      default = { };
      description = "Extra contacts accounts to configure.";
    };
    extraEmailAccounts = lib.mkOption {
      type =
        let
          accountType = lib.types.submodule {
            options = {
              enable = mkOpt lib.types.bool true "Enable this account";
              address = mkOpt lib.types.str null "Email address";
              flavor = mkOpt (lib.types.enum [
                "plain"
                "gmail.com"
                "runbox.com"
                "fastmail.com"
                "mailbox.org"
                "yandex.com"
                "outlook.office365.com"
                "davmail"
              ]) null "Email flavor";
            };
          };
        in
        lib.types.attrsOf accountType;
      default = { };
      description = "Extra email accounts to configure.";
    };
    filters = lib.mkOption {
      type =
        let
          filterType = lib.types.submodule {
            options = {
              enabled = mkOpt types.bool true "Whether this filter is currently active.";
              name = mkOpt types.str null "Descriptive filter name";
              type = mkOpt types.str null "Numeric code for filter type";
              action = mkOpt types.str null "Action to perform on matched messages.";
              actionValue = mkOpt types.str null "Argument passed to the filter action, e.g. a folder path.";
              condition = mkOpt types.str null "Condition to match messages against.";
            };
          };
        in
        lib.types.attrsOf filterType;
      default = {
        tagGH = {
          enabled = true;
          name = "Tag Github Emails";
          type = "81";
          action = "AddTag";
          actionValue = "github";
          condition = "AND (all addresses,contains,github)";
        };
        tagPers = {
          enabled = true;
          name = "Tag Personal Emails";
          type = "81";
          action = "AddTag";
          actionValue = "personal";
          condition = "OR (all addresses,contains,jhiller@ccn-law.com) OR (all addresses,contains,samovepros@live.com) OR (all addresses,contains,avidgolfer@me.com) OR (all addresses,contains,sunnydays352@yahoo.com)";
        };
      };
      description = "List of message filters to add to this Thunderbird account configuration.";
    };
  };

  config = mkIf cfg.enable {
    catppuccin = {
      enable = true;
      # don't autoenable all the module's ports
      autoEnable = false;
      thunderbird = {
        enable = true;
        flavor = "mocha";
        accent = "mauve";
      };
    };

    home.packages = with pkgs; [ birdtray ];

    programs.thunderbird = {
      enable = true;
      languagePacks = [
        "en-US"
        "en-AU"
      ];
      # settings applied to ALL profiles (optional)
      settings = {
      };
      # see https://thunderbird.github.io/policy-templates
      /*
        Status can be "default", "locked", "user" or "clear"
        "default": Read/Write: Settings appear as default even if factory default differs.
        "locked": Read-Only: Settings appear as default even if factory default differs.
        "user": Read/Write: Settings appear as changed if it differs from factory default.
        "clear": Read/Write: Value has no effect. Resets to factory defaults on each startup.
      */
      policies = {
        DisableFirefoxStudies = true; # this is set in Phoenix
        DisablePocket = true;
        DisableProfileImport = true;
        DisableTelemetry = true; # this is set in Phoenix
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true; # this is set in Pheonix
        # disable first run and update wizards
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = ""; # this is set in Phoenix
        # Preferences."browser.startup.page" = {
        # Open previous windows and tabs
        #   Status = "default";
        #   Value = "3";
        # };
        # override value from Phoenix?
        Preferences."browser.tabs.warnOnClose" = {
          Status = "locked";
          Value = "1";
        };
        # this is set in Phoenix
        # Preferences."widget.use-xdg-desktop-portal.file-picker" = {
        #   Status = "locked";
        #   Value = "1";
        # };
        PromptForDownloadLocation = true;
        SearchBar = "unified";
        TranslateEnabled = true;
      };
      profiles = {
        "${username}" = {
          isDefault = true;
          inherit (cfg) accountsOrder;
          # list available addons with "nix-env -f '<nixpkgs>' -qaP -A nur.repos.rycee.thunderbird-addons"
          # see https://github.com/nix-community/home-manager/pull/6033 for instructions on using
          # the buildFirefoxXpiAddon function to install addons not available there
          # extensions = with pkgs.nur.repos.rycee.thunderbird-addons; [ ];
          # Extra preferences to add to file user.js.
          extraConfig = "";
          # RSS or Atom feeds
          feedAccounts = {
            ${username} = { };
          };
          # search = {
          #   force = true;
          #   default = "ddg";
          #   privateDefault = "google";
          #   engines =
          #     let
          #       nixSnowflakeIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          #     in
          #     {
          #       "Nix Packages" = {
          #         urls = [
          #           {
          #             template = "https://search.nixos.org/packages";
          #             params = [
          #               {
          #                 name = "type";
          #                 value = "packages";
          #               }
          #               {
          #                 name = "channel";
          #                 value = "unstable";
          #               }
          #               {
          #                 name = "query";
          #                 value = "{searchTerms}";
          #               }
          #             ];
          #           }
          #         ];
          #         icon = nixSnowflakeIcon;
          #         definedAliases = [ "@nixp" ];
          #       };
          #       "Nix Options" = {
          #         urls = [
          #           {
          #             template = "https://search.nixos.org/options";
          #             params = [
          #               {
          #                 name = "channel";
          #                 value = "unstable";
          #               }
          #               {
          #                 name = "query";
          #                 value = "{searchTerms}";
          #               }
          #             ];
          #           }
          #         ];
          #         icon = nixSnowflakeIcon;
          #         definedAliases = [ "@nixo" ];
          #       };
          #       "Home Manager Options" = {
          #         urls = [
          #           {
          #             template = "https://home-manager-options.extranix.com/";
          #             params = [
          #               {
          #                 name = "query";
          #                 value = "{searchTerms}";
          #               }
          #               {
          #                 name = "release";
          #                 value = "master"; # unstable
          #               }
          #             ];
          #           }
          #         ];
          #         icon = nixSnowflakeIcon;
          #         definedAliases = [ "@hmo" ];
          #       };
          #     };
          # };
          settings = {
            "extensions.autoDisableScopes" = 0; # automatically enable extensions
            # "browser.display.use_system_colors" = true;
            # "browser.theme.dark-toolbar-theme" = true;
            # "calendar.timezone.useSystemTimezone" = true;
            # "datareporting.healthreport.uploadEnabled" = false;
            # "font.name.sans-serif.x-western" = "Rubik";
            # "font.size.variable.x-western" = 17;
            # "gfx.webrender.all" = true;
            # "gfx.webrender.enabled" = true;
            # "intl.regional_prefs.use_os_locales" = true; # Date and Time Formatting: Regional settings locale
            # "layers.acceleration.force-enabled" = true;
            # "mail.accounthub.enabled" = false; # OVERRIDE?
            # "mail.biff.play_sound" = false;
            # "mail.compose.big_attachments.notify" = false;
            # "mail.compose.default_to_paragraph" = false;
            # "mail.compose.double_line_spacing" = false;
            # "mail.shell.checkDefaultClient" = false; # already set in dove
            # "mail.spam.manualMark" = true;
            # "mail.tabs.drawInTitlebar" = true; # already set in dove
            "mailnews.default_sort_order" = 2; # descending, 1 for ascending
            # 17 = None
            # 18 = Date
            # 19 = Subject
            # 20 = Author
            # 21 = ID (Order Received)
            # 22 = Thread
            # 23 = Priority
            # 24 = Status
            # 25 = Size
            # 26 = Flagged
            # 27 = Unread
            # 28 = Recipient
            # 29 = Location
            # 30 = Label
            # 31 = Junk Status
            # 32 = Attachments
            # 33 = Account
            # 34 = Custom
            # 35 = Received
            # "mailnews.default_sort_type" = 18;
            # "mailnews.message_display.disable_remote_image" = false; # OVERRIDE?
            # "mailnews.start_page.enabled" = false; # already set in dove
            # https://superuser.com/a/13551
            # "mailnews.wraplength" = 80;
            # "messenger.startup.action" = 0;
            # "network.cookie.cookieBehavior" = 1;
            # "pdfjs.enabledCache.state" = true;
            # "privacy.donottrackheader.enabled" = true;
            # "privacy.fingerprintingProtection" = true;
            # "privacy.firstparty.isolate" = true;
            # "privacy.purge_trackers.date_in_cookie_database" = "0";
            # "privacy.resistFingerprinting" = true;
            # "privacy.trackingprotection.emailtracking.enabled" = true;
            # "privacy.trackingprotection.enabled" = true;
            # "privacy.trackingprotection.fingerprinting.enabled" = true;
            # "privacy.trackingprotection.socialtracking.enabled" = true;
            # "svg.context-properties.content.enabled" = true;
            # "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            # "toolkit.telemetry.enabled" = false;
          };
        };
      };
    };

    accounts = {
      calendar.accounts =
        let
          mkCalendarConfig =
            {
              url,
              type,
              color ? "#9a9cff",
            }:
            {
              remote = {
                inherit type url;
                userName = inputs.secrets.email.personal;
              };
              local = {
                inherit color;
              };
              thunderbird = {
                enable = true;
                profiles = [
                  username
                ];
                inherit color;
              };
            };
        in
        {
          # NOTE: to add new google calendars, go to the calendar's "settings and sharing" page and grab the
          # calendar ID. Then interpolate: "https://apidata.googleusercontent.com/caldav/v2/${calendar_id}/events/"
          "${inputs.secrets.email.personal}" = {
            remote = {
              type = "caldav";
              url = "https://apidata.googleusercontent.com/caldav/v2/${inputs.secrets.email.personal}/events/";
              userName = inputs.secrets.email.personal;
            };
            primary = true;
            thunderbird = {
              enable = true;
              profiles = [
                username
              ];
              color = "#16a765";
            };
          };
        }
        // lib.mapAttrs (_name: mkCalendarConfig) cfg.extraCalendarAccounts;

      contact.accounts =
        let
          mkContactsConfig =
            {
              url,
              type,
              color ? "#9a9cff",
            }:
            {
              remote = {
                inherit type url;
                userName = inputs.secrets.email.personal;
              };
              local = {
                inherit color;
              };
              thunderbird = {
                enable = true;
                profiles = [
                  username
                ];
                inherit color;
              };
            };
        in
        {
          "${inputs.secrets.email.personal}" = {
            remote = {
              type = "carddav";
              url = "https://www.googleapis.com/carddav/v1/principals/${inputs.secrets.email.personal}/";
              userName = inputs.secrets.email.personal;
            };
            primary = true;
            thunderbird = {
              enable = true;
              profiles = [
                username
              ];
              color = "#16a765";
            };
          };
        }
        // lib.mapAttrs (_name: mkContactsConfig) cfg.extraContactsAccounts;

      email.accounts =
        let
          thunderbirdFilters = [
            {
              name = "Tag Github Emails";
              enabled = true;
              type = "81";
              action = "AddTag";
              actionValue = "github";
              condition = "AND (all addresses,contains,github)";
            }
            {
              name = "Tag Personal Emails";
              enabled = true;
              type = "81";
              action = "AddTag";
              actionValue = "personal";
              condition = "OR (all addresses,contains,jhiller@ccn-law.com) OR (all addresses,contains,samovepros@live.com) OR (all addresses,contains,avidgolfer@me.com) OR (all addresses,contains,sunnydays352@yahoo.com)";
            }
          ];
          mkEmailConfig =
            {
              address,
              primary ? false,
              enable ? true,
              flavor,
            }:
            let
              finalEnable =
                if flavor == "davmail" && !config.mettavi.services.davmail.enable then
                  lib.warn "Davmail account '${address}' is disabled because davmail service is not enabled." false
                else
                  enable;
            in
            {
              enable = finalEnable;
              inherit
                address
                flavor
                primary
                ;
              realName = inputs.secrets.name;
              userName = lib.mkIf (flavor == "davmail") address;
              # aliases = [
              #   "mettavihari2021@gmail.com"
              # ];
              # signature = {
              #   showSignature = "append";
              #   text = (builtins.readFile ./cobalt_signature.html);
              # };
              thunderbird = {
                enable = finalEnable;
                messageFilters = thunderbirdFilters;
                profiles = [
                  username
                ];
                settings = _id: {
                };
              };
            };
        in
        {
          "${inputs.secrets.email.personal}" = mkEmailConfig {
            address = inputs.secrets.email.personal;
            primary = true;
            flavor = "gmail.com";
          };
        }
        // lib.mapAttrs (_name: mkEmailConfig) cfg.extraEmailAccounts;
    };
    # accounts = {
    #   "gmail-personal" = {
    #     # A command, which when run writes the account password on standard output
    #     passwordCommand = "cat ${config.sops.secrets."users/${username}/gmail_personal".path}";
    #     thunderbird = {
    #       settings = id: {
    #         # Enable HTML in signature
    #         "mail.identity.id_${id}.htmlSigFormat" = true;
    #         # Include signature on forwards
    #         "mail.identity.id_${id}.sig_on_fwd" = true;
    #         # Reply before the quoted text (gmail style)
    #         "mail.identity.id_${id}.reply_on_top" = 1;
    #         # Signature before the quoted text (gmail style)
    #         "mail.identity.id_${id}.sig_bottom" = false;
    #       };
    #     };
    #   };
    # };

    # define sops secrets for email accounts
    sops.secrets = {
      "users/${username}/email/${inputs.secrets.email.personal}" = emailSecrets;
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/mailto" = "thunderbird.desktop";
      };
    };
  };
}
