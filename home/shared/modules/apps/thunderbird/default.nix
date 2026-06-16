# Code adapted with thanks from:
# https://github.com/khaneliman/khanelinix/blob/0bff25ee02bc35540093118bff7106b460b9aad8/modules/home/programs/graphical/apps/thunderbird/default.nix
{
  config,
  inputs,
  lib,
  nix_repo,
  secrets_path,
  ...
}:
with lib;
let
  inherit (lib) mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.mettavi.apps.thunderbird;
  username = config.home.username;
  emailSecrets.sopsFile = "${secrets_path}/secrets/apps/email.yaml";
in
{
  imports = [ ./birdtray.nix ];

  options.mettavi.apps.thunderbird = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure the email client thunderbird";
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
              url = mkOption {
                type = lib.types.str;
                default = null;
                description = "Calendar url";
              };
              readOnly = mkOption {
                type = lib.types.bool;
                default = false;
                description = "Mark calendar as read-only";
              };
              type = mkOption {
                type = (
                  lib.types.enum [
                    "caldav"
                    "http"
                  ]
                );
                default = null;
                description = "Calendar flavor";
              };
            };
          };
        in
        lib.types.attrsOf accountType;
      default = {
        "Australian Holidays" = {
          # or use the public ical address?
          url = "https://calendar.google.com/calendar/ical/en.australian%23holiday%40group.v.calendar.google.com/public/basic.ics";
          readOnly = true;
          type = "http";
        };
        "Uposatha Moondays" = {
          # or use the public ical address?
          url = "http://splendidmoons.github.io/ical/mahanikaya.ical";
          readOnly = true;
          type = "http";
        };
      };
      description = "Extra calendar accounts to configure.";
    };
    extraContactsAccounts = lib.mkOption {
      type =
        let
          accountType = lib.types.submodule {
            options = {
              url = mkOption {
                type = lib.types.str;
                default = null;
                description = "Contacts url";
              };
              type = mkOption {
                type = (
                  lib.types.enum [
                    "carddav"
                    "http"
                    "google_contacts"
                  ]
                );
                default = null;
                description = "Contacts flavor";
              };
              # color = mkOpt lib.types.str null "color";
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
              enable = mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable this account";
              };
              accountFilters = mkOption {
                type = lib.types.listOf lib.types.str;
                default = builtins.attrNames cfg.filters;
                description = "Filters to use for a specific account";
              };
              address = mkOption {
                type = lib.types.str;
                default = null;
                description = "Email address";
              };
              aliases = mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Send-as aliases for this account";
              };
              flavor = mkOption {
                type = (
                  lib.types.enum [
                    "plain"
                    "gmail.com"
                    "runbox.com"
                    "fastmail.com"
                    "mailbox.org"
                    "yandex.com"
                    "outlook.office365.com"
                    "davmail"
                  ]
                );
                default = "gmail.com";
                description = "Email flavor";
              };
              realName = mkOption {
                type = lib.types.str;
                default = inputs.secrets.name;
                description = "Personal name of the account";
              };
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
              enabled = mkOption {
                type = types.bool;
                default = true;
                description = "Whether this filter is currently active.";
              };
              name = mkOption {
                type = types.str;
                default = null;
                description = "Descriptive filter name";
              };
              type = mkOption {
                type = types.str;
                default = null;
                description = "Numeric code for filter type";
              };
              action = mkOption {
                type = types.str;
                default = null;
                description = "Action to perform on matched messages.";
              };
              actionValue = mkOption {
                type = types.str;
                default = null;
                description = "Argument passed to the filter action, e.g. a folder path.";
              };
              condition = mkOption {
                type = types.str;
                default = null;
                description = "Condition to match messages against.";
              };
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
          actionValue = "Github";
          condition = "AND (all addresses,contains,github)";
        };
        tagPers = {
          enabled = true;
          name = "Tag Personal Emails";
          type = "81";
          action = "AddTag";
          actionValue = "Personal";
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
      # profiles are saved to ~/.thunderbird on nixos and not to XDG_CONFIG_HOME by default,
      # and there is currently no easy setting to change it
      # See https://github.com/nix-community/home-manager/pull/8456
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
          # feedAccounts = {
          #   ${username} = { };
          # };
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
            # compact imap mail folders regularly without asking first
            # see https://support.mozilla.org/en-US/kb/compacting-folders
            "mail.purge.ask" = false;
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
            # Add a new tag to be used in the message filter
            "mailnews.tags.github.color" = "#BB40BF";
            "mailnews.tags.github.tag" = "Github";
            # https://superuser.com/a/13551
            # "mailnews.wraplength" = 80;
            # "messenger.startup.action" = 0;
            # "network.cookie.cookieBehavior" = 1;
            # override the dove settings; do not prompt before going online on launch
            # 0 = remember previous, 1 = ask, 2 = online, 3 = offline
            "offline.startup_state" = 2;
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
              readOnly,
              type,
            }:
            {
              remote = {
                inherit type url;
                userName = inputs.secrets.email.personal;
              };
              thunderbird = {
                inherit readOnly;
                enable = true;
                profiles = [
                  username
                ];
              };
            };
        in
        {
          # To add new google calendars, go to the calendar's "settings and sharing" page and grab the
          # calendar ID. Then interpolate: "https://apidata.googleusercontent.com/caldav/v2/${calendar_id}/events/"
          # NB: The trailing slash is required
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
            }:
            {
              remote = {
                inherit type url;
                userName = inputs.secrets.email.personal;
              };
              thunderbird = {
                enable = true;
                profiles = [
                  username
                ];
              };
            };
        in
        {
          "${inputs.secrets.email.personal}" = {
            remote = {
              type = "carddav";
              url = "https://www.googleapis.com/carddav/v1/principals/${inputs.secrets.email.personal}/lists/default/";
              userName = inputs.secrets.email.personal;
            };
            thunderbird = {
              enable = true;
              profiles = [
                username
              ];
            };
          };
        }
        // lib.mapAttrs (_name: mkContactsConfig) cfg.extraContactsAccounts;

      email.accounts =
        let
          mkEmailConfig =
            {
              enable ? true,
              address,
              accountFilters ? builtins.attrNames cfg.filters,
              aliases ? [ ],
              flavor ? "gmail.com",
              primary ? false,
              realName ? inputs.secrets.name,
            }:
            let
              filterNames = lib.filterAttrs (name: value: builtins.elem name accountFilters) cfg.filters;
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
                aliases
                flavor
                primary
                realName
                ;
              passwordCommand = "cat ${config.sops.secrets."users/email/${username}/${address}".path}";
              signature = {
                delimiter = ''
                  ~*~*~*~*~*~*~*~*~*~*~*~
                '';
                showSignature = "append";
                text = ''
                  ${realName}
                  ${address}
                '';
              };
              userName = lib.mkIf (flavor == "davmail") address;
              thunderbird = {
                enable = finalEnable;
                messageFilters = builtins.attrValues filterNames;
                profiles = [
                  username
                ];
                perIdentitySettings = id: { };
                settings = id: {
                  # Explicitly lock friendly paths based on the email address username
                  "mail.server.server_${id}.directory" =
                    "/home/${username}/.thunderbird/${username}/ImapMail/${builtins.head (lib.splitString "@" address)}";
                  "mail.server.server_${id}.directory-rel" =
                    "[ProfD]ImapMail/${builtins.head (lib.splitString "@" address)}";

                  "mail.server.server_${id}.autosync_max_age_days" = 30;
                  # Reply before the quoted text (gmail style)
                  "mail.identity.id_${id}.reply_on_top" = 1;
                  # Signature before the quoted text (gmail style)
                  "mail.identity.id_${id}.sig_bottom" = false;
                  # Include signature on forwards
                  "mail.identity.id_${id}.sig_on_fwd" = true;
                  # Enable HTML in signature
                  "mail.identity.id_${id}.htmlSigFormat" = false;
                };
              };
            };
        in
        {
          "${inputs.secrets.email.personal}" = mkEmailConfig {
            address = inputs.secrets.email.personal;
            aliases = [ inputs.secrets.email.monk ];
            primary = true;
          };
        }
        // lib.mapAttrs (_name: mkEmailConfig) cfg.extraEmailAccounts;
    };

    # link without copying to nix store (manage externally) - must use absolute paths
    home.file.".thunderbird/${username}/persdict.dat" = {
      source = mkOutOfStoreSymlink "${config.home.homeDirectory}/${nix_repo}/home/shared/modules/apps/thunderbird/persdict.dat";
    };

    # define sops secrets for these main email accounts on all hosts
    # other accounts are specified in the host config
    sops.secrets = {
      "users/${username}/email/${inputs.secrets.email.monk}" = emailSecrets;
      "users/${username}/email/${inputs.secrets.email.personal}" = emailSecrets;
    };

    # https://github.com/gyunaev/birdtray/issues/426
    # This fixes birdtray not being able to see if thunderbird is running, because birdtray doesn't
    #  have good wayland support.
    xdg.desktopEntries.thunderbird = {
      name = "Thunderbird";
      actions = {
        "profile-manager-window" = {
          exec = "env GDK_BACKEND=x11 thunderbird -ProfileManager";
          name = "Profile Manager";
        };
      };
      categories = [
        "Network"
        "Chat"
        "Email"
        "Feed"
        "GTK"
        "News"
      ];
      comment = "Read and write e-mails or RSS feeds, or manage tasks on calendars.";
      exec = "env GDK_BACKEND=x11 thunderbird --name thunderbird %U";
      genericName = "Email Client";
      icon = "thunderbird";
      mimeType = [
        "message/rfc822"
        "x-scheme-handler/mailto"
        "text/calendar"
        "text/x-vcard"
      ];
      settings = {
        Keywords = "mail;email;e-mail;messages;rss;calendar;address book;addressbook;chat";
        StartupWMClass = "thunderbird";
      };
      startupNotify = true;
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/mailto" = "thunderbird.desktop";
      };
    };
  };
}
