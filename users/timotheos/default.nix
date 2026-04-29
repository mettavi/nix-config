{
  config,
  lib,
  pkgs,
  ...
}:
{
  dconf.settings = {
    # add custom keybindings for ASUS linux utilities
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "ROG Control Center";
      command = "rog-control-center";
      # on the keyboard this is the M4 key
      binding = "Launch1";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Next Power Mode";
      command = "asusctl profile next";
      # on the main keyboard this is Fn-F5
      binding = "Launch4";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "Next Aura Mode";
      command = "asusctl leds next";
      # on the main keyboard this is Fn-F4
      binding = "Launch3";
    };
    "org/gnome/shell" = {
      # `gnome-extensions list` for a list
      enabled-extensions = [
        "gpu-switcher-supergfxctl@chikobara.github.io"
      ];
    };
  };
  home = {
    packages = with pkgs; [
      # Simple GPU Profile switcher for ASUS laptops using Supergfxctl
      gnomeExtensions.gpu-supergfxctl-switch
      goldendict-ng # Advanced multi-dictionary lookup program
      gramps # Genealogy software
    ];
    sessionVariables = {
      # required for electron apps, which don't read the mimeapps.list file
      DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
    };
    stateVersion = "25.11";
  };
  # install the HTML manual and "home-manager-help" command
  manual.html.enable = true;

  mettavi = {
    apps = {
      anki.enable = true;
      firefox.enable = true;
      ghostty.enable = true;
      obsidian.enable = true;
      zotero = {
        enable = false;
        profiles.default = {
          settings =
            let
              # Chicago Manual of Style [latest] edition (note)
              style = "http://www.zotero.org/styles/chicago-note-bibliography";
              locale = "en-US";
            in
            {
              # See <https://www.zotero.org/support/preferences/hidden_preferences> also.
              "general.smoothScroll" = false;
              "intl.accept_language" = "en-US, en";

              # Use the flake-provided versions of translators and styles.
              # "extensions.zotero.automaticScraperUpdates" = false;
              "extensions.zotero.automaticScraperUpdates" = true;

              "extensions.zotero.findPDFs.resolvers" = [
                {
                  "name" = "Sci-Hub";
                  "method" = "GET";
                  "url" = "https://sci-hub.ru/{doi}";
                  "mode" = "html";
                  "selector" = "#pdf";
                  "attribute" = "src";
                  "automatic" = true;
                }
                {
                  "name" = "Google Scholar";
                  "method" = "GET";
                  "url" = "{z:openURL}https://scholar.google.com/scholar?q=doi%3A{doi}";
                  "mode" = "html";
                  "selector" = ".gs_or_ggsm a:first-child";
                  "attribute" = "href";
                  "automatic" = true;
                }
              ];

              # Sort settings
              "extensions.zotero.sortAttachmentsChronologically" = true;
              "extensions.zotero.sortNotesChronologically" = true;

              # Item adding settings
              "extensions.zotero.automaticSnapshots" = true; # Take snapshots of webpages when items are made from them
              "extensions.zotero.translators.RIS.import.ignoreUnknown" = false; # Don't discard unknown RIS tags when importing
              "extensions.zotero.translators.attachSupplementary" = true; # "Translators should attempt to attach supplementary data when importing items"

              # Citation settings
              "extensions.zotero.export.lastStyle" = style;
              "extensions.zotero.export.quickCopy.locale" = locale;
              "extensions.zotero.export.quickCopy.setting" = "bibliography=${style}";
              "extensions.zotero.export.citePaperJournalArticleURL" = false;

              # Feed options
              "extensions.zotero.feeds.defaultTTL" = 24 * 7; # Refresh feeds every week
              "extensions.zotero.feeds.defaultCleanupReadAfter" = 60; # Clean up read feed items after 60 days
              "extensions.zotero.feeds.defaultCleanupUnreadAfter" = 90; # Clean up unread feed items after 90 days

              # Attachment settings
              "extensions.zotero.useDataDir" = true;
              "extensions.zotero.dataDir" = "${config.xdg.dataHome}/zotero";

              # Reading settings
              "extensions.zotero.tabs.title.reader" = "filename"; # Show filename in tab title

              # Sync settings
              "extensions.zotero.sync.storage.enabled" = true;
              "extensions.zotero.sync.protocol" = "webdav";
              "extensions.zotero.sync.storage.url" = "files.box.somas.is";
              "extensions.zotero.sync.storage.username" = "zotero";

              # "extensions.zotero.attachmentRenameFormatString" = "{%c - }%t{100}{ (%y)}"; # Set the file name format used by Zotero's internal stuff

              "extensions.zotero.autoRenameFiles.fileTypes" = lib.concatStringsSep "," [
                "application/pdf"
                "application/epub+zip"
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                "application/vnd.oasis.opendocument.text"
              ];

              # Zotero OCR
              "extensions.zotero.zoteroocr.pdftoppmPath" = "${pkgs.poppler-utils}/bin/pdftoppm";
              "extensions.zotero.zoteroocr.ocrPath" = "${pkgs.tesseract}/bin/tesseract";
              "extensions.zotero.zoteroocr.language" = "eng";

              "extensions.zotero.zoteroocr.outputPDF" = true; # Output options > "Save output as a PDF with text layer"
              "extensions.zotero.zoteroocr.overwritePDF" = true; # Output options > "Save output as a PDF with text layer" > "Overwrite the initial PDF with the output"

              "extensions.zotero.zoteroocr.outputHocr" = false; # Output options > "Save output as a HTML/hocr file(s)"
              "extensions.zotero.zoteroocr.outputNote" = false; # Output options > "Save output as a note"
              "extensions.zotero.zoteroocr.outputPNG" = false; # Output options > "Save the intermediate PNGs as well in the folder"

              "ui.use_activity_cursor" = true;

              # LibreOffice extension settings
              "extensions.zotero.integration.useClassicAddCitationDialog" = true;
              "extensions.zoteroOpenOfficeIntegration.installed" = true;
              "extensions.zoteroOpenOfficeIntegration.skipInstallation" = true;

              "extensions.zotero.reader.ebookFontFamily" = "serif";

              # "extensions.zotero.openReaderInNewWindow" = true;

              # ouch
              "extensions.zotero.attachmentRenameTemplate" = ''
                {{ if {{ creators }} != "" }}{{ if {{ creators max="1" name-part-separator=", " }} == {{ creators max="1" name="family-given" }}, }}{{ creators max="2" name="family-given" join=", " suffix=" - " }}{{ else }}{{ if {{ creators max="1" }} != {{ creators max="2" }} }}{{ creators max="1" name="family-given" name-part-separator=", " join=", " suffix=" et al. - " }}{{ else }}{{ creators max="2" name="family-given" name-part-separator=", " join=", " suffix=" - " }}{{ endif }}{{ endif }}{{ else }}{{ creators max="1" name="family-given" name-part-separator=", " }}{{ endif }}{{ if shortTitle != "" }}{{ shortTitle }}{{ else }}{{ if {{ title truncate="80" }} == {{ title }} }}{{ title }}{{ else }}{{ title truncate="80" suffix="..." }}{{ endif }}{{ endif }}{{ if itemType == "book" }} ({{ year }}{{ publisher truncate="80" prefix=", " }}){{ elseif itemType == "bookSection" }} ({{ year }}{{ bookTitle prefix=", " truncate="80" }}){{ elseif itemType == "blogpost" }} ({{ if year != "" }}{{ year }}{{ blogTitle prefix=", " }}{{ else }}{{ blogTitle }}{{ endif }}){{ elseif itemType == "webpage" }} ({{ year }}{{ websiteTitle prefix=", " }}){{ elseif itemType == "newspaperArticle" }} ({{ year }}{{ publicationTitle truncate="80" prefix=", " }}{{ section truncate="80" prefix=", " }}){{ elseif itemType == "presentation" }} ({{ year }}{{ meetingName truncate="80" prefix=", " }}){{ elseif publicationTitle != "" }} ({{ year }}{{ publicationTitle truncate="80" prefix=", " }}{{ if volume != year }}{{ volume prefix=" "  }}{{ endif }}{{ issue prefix=", no. " }}){{ elseif year != "" }} ({{ year }}){{ endif }}
              '';
              "extensions.zotero.autoRenameFiles.linked" = true;

              # <https://github.com/MuiseDestiny/zotero-attanger>
              "extensions.zotero.zoteroattanger.sourceDir" = config.xdg.userDirs.download;
              "extensions.zotero.zoteroattanger.readPDFtitle" = "always";
              "extensions.zotero.zoteroattanger.attachType" = "importing";
              "extensions.zotero.zoteroattanger.destDir" = "${config.xdg.userDirs.documents}/articles";
              "extensions.zotero.zoteroattanger.autoRemoveEmptyFolder" = true;
              "extensions.zotero.zoteroattanger.fileTypes" = lib.concatStringsSep "," [
                "pdf"
                "epub"
                "docx"
                "odt"
              ];

              # Enable userChrome
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };
          userChrome = ''
            * {
                /* Disable animations */
                transition: none !important;
                transition-duration: 0 !important;

                /* Square everything */
                border-radius: 0 !important;

                /* No shadows */
                box-shadow: none !important;
            }

            :root {
                --tab-min-height: 44px;
            }

            :root:not([legacytoolbar="true"]) {
                --tab-min-height: 36px;
            }

            /* Use Arc's style for toolbars */
            #titlebar {
                background: ${config.theme.colors.toolbarBackground} !important; /* config.theme.colors.background */
                color: ${config.theme.colors.toolbarForeground} !important; /* config.theme.colors.foreground */
            }
          '';
        };
      };
    };
  };
  shell = {
    bash.enable = true;
    nh.enable = true;
    tmux.enable = true;
    yazi.enable = true;
    # zsh is enabled by default
  };

  xdg.mimeApps = {
    enable = true;
    /*
      To list all .desktop files, run:
      ls /run/current-system/sw/share/applications # for global packages
      ls /etc/profiles/per-user/$(id -n -u)/share/applications # for user packages
    */
    # See http://discourse.nixos.org/t/how-can-i-configure-the-default-apps-for-gnome/36034
    defaultApplications = {
      # gnome image viewer
      "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
      # gnome document viewer
      "application/pdf" = [ "org.gnome.Evince.desktop" ];
      "default-web-browser" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };
}
