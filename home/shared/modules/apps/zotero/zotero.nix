{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  study = "${config.home.homeDirectory}/study";
in
{
  mettavi.apps.zotero = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.xpkgs.zotero-addons; [
        # MY EXTENSIONS
        # zotero-addon-market
        # zotero-attanger
        # zotero-better-bibtex
        zotero-reading-list
        # OTHER EXTENSIONS
        # zotero-abstract-cleaner
        # zotero-auto-index
        # zotero-ocr
        # zotero-open-pdf
        # zotero-preview
        # zotero-robustlinks
        # zotero-storage-scanner
        # zotmoov
        # zotero-delitemwithatt
        # scite-zotero
        # cita
        # ai-research-assistant
        #zotero-gpt
        # zotero-better-notes
      ];
      settings =
        let
          # Chicago Manual of Style [latest] edition (note)
          style = "http://www.zotero.org/styles/chicago-note-bibliography";
          locale = "en-AU";
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
          # linked attachments are not compatible with webdav syncing (see below)
          "extensions.zotero.saveRelativeAttachmentPath" = false;
          "extensions.zotero.baseAttachmentPath" = "${study}/zotero";

          # Reading settings
          "extensions.zotero.tabs.title.reader" = "filename"; # Show filename in tab title

          # Sync settings
          "extensions.zotero.sync.storage.enabled" = true;
          "extensions.zotero.sync.protocol" = "webdav";
          "extensions.zotero.sync.storage.url" = "https://app.koofr.net/dav/Koofr";
          "extensions.zotero.sync.storage.username" = "${inputs.secrets.email.personal}";

          "extensions.zotero.attachmentRenameFormatString" =
            "{{ firstCreator suffix=\" - \" }}{{ year suffix=\" - \" }}{{ title truncate=\"100\" }}"; # Set the file name format used by Zotero's internal stuff

          "extensions.zotero.autoRenameFiles.fileTypes" = lib.concatStringsSep "," [
            "application/pdf"
            "application/epub+zip"
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "application/vnd.oasis.opendocument.text"
          ];

          # Zotero OCR
          # "extensions.zotero.zoteroocr.pdftoppmPath" = "${pkgs.poppler-utils}/bin/pdftoppm";
          # "extensions.zotero.zoteroocr.ocrPath" = "${pkgs.tesseract}/bin/tesseract";
          # "extensions.zotero.zoteroocr.language" = "eng";
          #
          # "extensions.zotero.zoteroocr.outputPDF" = true; # Output options > "Save output as a PDF with text layer"
          # "extensions.zotero.zoteroocr.overwritePDF" = true; # Output options > "Save output as a PDF with text layer" > "Overwrite the initial PDF with the output"
          #
          # "extensions.zotero.zoteroocr.outputHocr" = false; # Output options > "Save output as a HTML/hocr file(s)"
          # "extensions.zotero.zoteroocr.outputNote" = false; # Output options > "Save output as a note"
          # "extensions.zotero.zoteroocr.outputPNG" = false; # Output options > "Save the intermediate PNGs as well in the folder"

          "ui.use_activity_cursor" = true;

          # Recursive view of articles in the hierarchy
          "extensions.zotero.recursiveCollections" = true;

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
          # "extensions.zotero.zoteroattanger.sourceDir" = config.xdg.userDirs.download;
          # "extensions.zotero.zoteroattanger.readPDFtitle" = "always";
          # "extensions.zotero.zoteroattanger.attachType" = "importing";
          # "extensions.zotero.zoteroattanger.destDir" = "${config.xdg.userDirs.documents}/articles";
          # "extensions.zotero.zoteroattanger.autoRemoveEmptyFolder" = true;
          # "extensions.zotero.zoteroattanger.fileTypes" = lib.concatStringsSep "," [
          #   "pdf"
          #   "epub"
          #   "docx"
          #   "odt"
          # ];

          # Enable userChrome
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        }
      # TODO Other extensions settings to be enabled
      # // {
      #   # Add-ons > Robust Links (Item adding settings)
      #   "extensions.robustlinks.archiveonadd" = "yes";
      #   "extensions.robustlinks.whatarchive" = "random";

      #   # Add-ons > Citation settings
      #   "extensions.zoteropreview.citationstyle" = style; # Zotero Citation Preview

      #   # Add-ons > DOI Manager
      #   "extensions.shortdoi.tag_invalid" = "#invalid_doi";
      #   "extensions.shortdoi.tag_multiple" = "#multiple_doi";
      #   "extensions.shortdoi.tag_nodoi" = "#no_doi";

      # Add-ons > Zotero PDF Preview
      # "extensions.zotero.pdfpreview.previewTabName" = "PDF"; # Default tab name clashes with Zotero Citation Preview

      #   # Add-ons > Zotero AutoIndex
      #   "extensions.zotero.fulltext.pdfMaxPages" = 1024;

      # <https://github.com/wileyyugioh/zotmoov>
      # "extensions.zotmoov.dst_dir" = "${study}/doc";
      # "extensions.zotmoov.allowed_fileext" = [ "pdf" "epub" "docx" "odt" ];
      # "extensions.zotmoov.delete_files" = true;
      ;
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
      '';
      # };
    };
  };

  # install the firefox extension
  programs.firefox.profiles."mettavi".extensions.packages =
    with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
    optionals (config.mettavi.apps.firefox.enable) [ zotero-connector ];

  xdg.dataFile = {
    # "zotero/storage".source =
    #   config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/study/zotero";

    # "zotero/styles".source = inputs.zotero-styles;
    # "zotero/translators".source = inputs.zotero-translators;

    "zotero/locate/.keep".source = builtins.toFile "keep" "";
    "zotero/locate/engines.json".text = builtins.toJSON [
      {
        _hidden = false;

        _name = "WorldCat";
        _alias = "WorldCat";
        _description = "WorldCat Search";
        _icon = "https://worldcat.org/favicons/favicon-16x16.png";

        _urlTemplate = "https://worldcat.org/search?q=bn%3A{rft:isbn}+AND+ti%3A{z:title}+AND+au%3A{rft:aufirst?}+{rft:aulast?}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "CrossRef Lookup";
        _alias = "CrossRef";
        _description = "CrossRef Search Engine";
        _icon = "https://crossref.org/favicon.ico";

        _urlTemplate = "https://crossref.org/openurl?{z:openURL}&pid=zter:zter321";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
        };
      }

      {
        _hidden = false;

        _name = "Google Scholar";
        _alias = "Google Scholar";
        _description = "Google Scholar Search";
        _icon = "https://scholar.google.com/favicon.ico";

        _urlTemplate = "https://scholar.google.com/scholar?as_q=&as_epq={z:title}&as_occt=title&as_sauthors={rft:aufirst?}+{rft:aulast?}&as_ylo={z:year?}&as_yhi={z:year?}&as_sdt=1.&as_sdtp=on&as_sdtf=&as_sdts=22&";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx";
        };
      }
      {
        _hidden = false;

        _name = "Google Scholar (title only)";
        _alias = "Google Scholar (title)";
        _description = "Google Scholar Search (title only)";
        _icon = "https://scholar.google.com/favicon.ico";

        _urlTemplate = "https://scholar.google.com/scholar?as_q=&as_epq={z:title}&as_occt=title&as_sdt=1.&as_sdtp=on&as_sdtf=&as_sdts=22&";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "Thriftbooks";
        _alias = "Thriftbooks";
        _description = "Search Thriftbooks";
        _icon = "https://static.thriftbooks.com/images/favicon.ico";

        _urlTemplate = "https://www.thriftbooks.com/viewDetails.aspx?ASIN={rft:isbn}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "Abebooks";
        _alias = "Abebooks";
        _description = "Search Abebooks";
        _icon = "https://www.abebooks.com/favicon.ico";

        _urlTemplate = "https://www.abebooks.com/servlet/SearchResults?isbn={rft:isbn}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "Anna's Archive";
        _alias = "Anna's";
        _description = "Search Anna's Archive";
        _icon = "https://annas-archive.org/favicon-32x32.png";

        _urlTemplate = "https://annas-archive.org/search?index=&q={rft:isbn}+{z:DOI}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx";
        };
      }

      {
        _hidden = false;

        _name = "12ft.io";
        _alias = "12ft.io";
        _description = "Show me a 10ft paywall, I'll show you a 12ft ladder";
        _icon = "https://12ft.io/favicon.png";

        _urlTemplate = "https://12ft.io/api/proxy?q={z:url}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
        };
      }

      {
        _hidden = false;

        _name = "Unpaywall";
        _alias = "Unpaywall";
        _description = "Unpaywall Lookup";
        _icon = "https://oadoi.org/static/img/favicon.png";

        _urlTemplate = "https://oadoi.org/{z:DOI}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:journal";
        };
      }
    ];
  };

  xdg.mimeApps = {
    defaultApplications = lib.genAttrs [
      "application/marc"
      "application/rdf+xml"
      "application/x-research-info-systems"
      "text/x-bibtex"
    ] (_: [ "zotero.desktop" ]);
  };
}
