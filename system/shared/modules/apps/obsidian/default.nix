{
  config,
  inputs,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.apps.obsidian;
  jsonFormat = pkgs.formats.json { };
in
{
  options.mettavi.apps.obsidian = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure Obsidian";
    };
    pinnedSettings = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            app = mkOption {
              type = types.nullOr jsonFormat.type;
              default = null;
              description = "Keys merged into this vault's app.json. Anything else already there (set via the GUI) is preserved.";
            };
            appearance = mkOption {
              type = types.nullOr jsonFormat.type;
              default = null;
              description = "Keys merged into this vault's appearance.json.";
            };
            hotkeys = mkOption {
              type = types.nullOr jsonFormat.type;
              default = null;
              description = "Keys merged into this vault's hotkeys.json.";
            };
            corePlugins = mkOption {
              type = types.attrsOf jsonFormat.type;
              default = { };
              description = "Core plugin name -> keys merged into its settings file (e.g. `templates.json`, `bookmarks.json`) at the root of .obsidian/.";
            };
            plugins = mkOption {
              type = types.attrsOf jsonFormat.type;
              default = { };
              description = "Plugin manifest id -> keys merged into that plugin's data.json.";
            };
            files = mkOption {
              type = types.attrsOf jsonFormat.type;
              default = { };
              description = "Escape hatch: path relative to .obsidian/ -> keys merged into that JSON file.";
            };
          };
        }
      );
      default = { };
      description = ''
        Per-vault settings merged (via jq) into the live, GUI-editable
        Obsidian config files, rather than fully replacing them as
        `programs.obsidian.vaults.<name>.settings` does. Keyed by the
        same vault path used there. Do not set both
        `programs.obsidian.vaults.<name>.settings.<x>` and
        `pinnedSettings.<name>.<x>` for the same file — the plain
        Nix-managed symlink will win and your merged patch will be
        discarded on the next activation.
      '';
    };
  };

  config = mkIf cfg.enable {
    # enable pkgs.obsidianPlugins and pkgs.obsidianThemes from the obsidian-extensions flake
    nixpkgs.overlays = [
      inputs.obsidian-extensions.overlays.default
    ];

    mettavi.apps.obsidian = {
      # any settings included here will be MERGED by an activation script with any values set by the GUI
      pinnedSettings = {
        "Documents/Evernote" = {
          app.alwaysUpdateLinks = true;
          corePlugins = {
            templates.folder = "Utilities/Templates"; # flat file — safe to pin
            # bookmarks = { ... };  # DON'T — bookmarks.json is essentially one big
            # `items` array; pinning anything here would
            # wipe out GUI-added bookmarks on next rebuild.
            # Leave bookmarks.json out of both `corePlugins`
            # here and `programs.obsidian...corePlugins`
            # entirely if you want it GUI-owned.
          };
        };
        # "Documents/Personal Notes" = {
        #   app.spellcheck = true;
        #   hotkeys."command-palette:open" = [
        #     {
        #       modifiers = [ "Mod" ];
        #       key = "P";
        #     }
        #   ];
        # };
      };
    };

    home-manager.users.${username} = { config, ... }: {
      assertions = lib.mapAttrsToList (vaultName: vaultCfg: {
        assertion =
          let
            declared =
              config.home-manager.users.${username}.programs.obsidian.vaults.${vaultName}.settings or null;
          in
          declared == null
          || (
            (vaultCfg.app == null || declared.app == null)
            && (vaultCfg.appearance == null || declared.appearance == null)
            && (vaultCfg.hotkeys == null || declared.hotkeys == null)
          );
        message = "mettavi.apps.obsidian.pinnedSettings.\"${vaultName}\" overlaps with programs.obsidian.vaults.\"${vaultName}\".settings on app/appearance/hotkeys — pick one mechanism per file.";
      }) cfg.pinnedSettings;

      home.activation.obsidianPinnedSettings =
        let
          jq = lib.getExe pkgs.jq;

          mkPatch =
            path: values:
            let
              patchFile = jsonFormat.generate "patch.json" values;
            in
            ''
              target=${lib.escapeShellArg path}
              mkdir -p "$(dirname "$target")"
              [ -f "$target" ] || echo '{}' > "$target"
              tmp="$(mktemp)"
              ${jq} -s '(.[0] // {}) * (.[1] // {})' "$target" ${lib.escapeShellArg patchFile} > "$tmp"
              install -m644 "$tmp" "$target"
              rm -f "$tmp"
            '';

          mkVaultPatches =
            vaultName: vaultCfg:
            let
              obsidianDir = "${config.home.homeDirectory}/${vaultName}/.obsidian";
            in
            lib.concatStrings (
              lib.optional (vaultCfg.app != null) (mkPatch "${obsidianDir}/app.json" vaultCfg.app)
              ++ lib.optional (vaultCfg.appearance != null) (
                mkPatch "${obsidianDir}/appearance.json" vaultCfg.appearance
              )
              ++ lib.mapAttrsToList (
                pluginName: values: mkPatch "${obsidianDir}/${pluginName}.json" values
              ) vaultCfg.corePlugins
              ++ lib.optional (vaultCfg.hotkeys != null) (mkPatch "${obsidianDir}/hotkeys.json" vaultCfg.hotkeys)
              ++ lib.mapAttrsToList (
                pluginId: values: mkPatch "${obsidianDir}/plugins/${pluginId}/data.json" values
              ) vaultCfg.plugins
              ++ lib.mapAttrsToList (relPath: values: mkPatch "${obsidianDir}/${relPath}" values) vaultCfg.files
            );
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] (
          lib.concatStrings (lib.mapAttrsToList mkVaultPatches cfg.pinnedSettings)
        );

      programs.obsidian = {
        enable = true;
        # NB: Vault-specific settings take priority and will override these, if set.
        defaultSettings = {
          app = {
            alwaysUpdateLinks = true;
            spellcheck = true;
          };
          # NB: Any plugin's settings configured here AND/OR in a vault's settings
          # will overwrite ALL its GUI-configured settings (if set)
          # Core plugins omitted from this list are disabled.
          corePlugins = [
            "audio-recorder"
            "backlink"
            "bases"
            "bookmarks"
            "canvas"
            "command-palette"
            "daily-notes"
            "editor-status"
            "file-explorer"
            "file-recovery"
            "footnotes"
            "global-search"
            "graph"
            "markdown-importer"
            "note-composer"
            "outgoing-link"
            "outline"
            "page-preview"
            "properties"
            "publish"
            "random-note"
            "slash-command"
            "slides"
            "switcher"
            "sync"
            "tag-pane"
            "templates"
            "webviewer"
            "word-count"
            "workspaces"
            "zk-prefixer"
          ];
          communityPlugins = with pkgs.obsidianPlugins; [
            # BARE PACKAGE (COERCED TO { PKG = P; }): SETTINGS DEFAULTS TO NULL.
            # -> INSTALLED + ENABLED VIA NIX, DATA.JSON FULLY GUI-MANAGED.
            obsidian-importer
            omnisearch
            # SAME THING, SPELLED OUT, PLUS EXPLICIT ENABLE CONTROL:
            # {
            #   pkg = pkgs.obsidianPlugins.templater-obsidian;
            #   enable = true;
            # # no `settings` key here -> data.json is GUI territory
            # }
            # INSTALLED BUT CURRENTLY SWITCHED OFF (STILL NIX-CONTROLLED TOGGLE):
            # {
            #   pkg = pkgs.obsidianPlugins.highlightr-plugin;
            #   enable = false;
            # }
            # FULLY NIX-MANAGED (NO GUI), FOR COMPARISON:
            # {
            #   enable = true;
            #   pkg = pkgs.obsidianPlugins.omnisearch;
            #   # Settings to include in the plugin’s data.json.
            #   settings = {
            #     ribbonIcon = true; # data.json fully replaced every activation
            #   };
            # }
          ];
          themes = with pkgs.obsidianThemes; [
            catppuccin
          ];
        };
        # Settings for any attribute here will replace ALL those set through the GUI;
        # Omit them here to set via the GUI and/or merge any desired settings
        # with `mettavi.apps.obsidian.pinnedSettings` (see above) instead.
        vaults = {
          "Documents/Evernote" = {
            enable = true;
          };
          "Documents/VaultsTest/AABCAP 2025-26" = {
            enable = false;
            settings = {
              app = {
                attachmentFolderPath = "Utilities/Assets/";
                promptDelete = false;
                showUnsupportedFiles = true;
              };
              communityPlugins = [
                {
                  pkg = pkgs.callPackage ./plugins/custom-sort { };
                  settings = {
                    "additionalSortspecFile" = "";
                    "indexNoteNameForFolderNotes" = "";
                    "suspended" = false;
                    "statusBarEntryEnabled" = true;
                    "notificationsEnabled" = true;
                    "mobileNotificationsEnabled" = false;
                    "customSortContextSubmenu" = true;
                    "automaticBookmarksIntegration" = true;
                    "bookmarksContextMenus" = true;
                    "bookmarksGroupToConsumeAsOrderingReference" = "sortspec";
                    "delayForInitialApplication" = 1000;
                  };
                }
                {
                  pkg = "highlightr-plugin";
                  settings = {
                    "highlighterStyle" = "none";
                    "highlighterMethods" = "inline-styles";
                    "highlighters" = {
                      "Pink" = "#FFB8EBA6";
                      "Red" = "#FF5582A6";
                      "Orange" = "#FFB86CA6";
                      "Yellow" = "#FFF3A3A6";
                      "Green" = "#BBFABBA6";
                      "Cyan" = "#ABF7F7A6";
                      "Blue" = "#ADCCFFA6";
                      "Purple" = "#D2B3FFA6";
                      "Grey" = "#CACFD9A6";
                      "Magenta" = "#F272D4";
                    };
                    "highlighterOrder" = [
                      "Pink"
                      "Red"
                      "Orange"
                      "Yellow"
                      "Green"
                      "Cyan"
                      "Blue"
                      "Purple"
                      "Grey"
                      "Magenta"
                    ];
                  };
                }
                {
                  pkg = "obsidian-custom-attachment-location";
                  settings = {
                    "attachmentFolderPath" = "Utilities/Assets/\${noteFolderName}/\${noteFileName}";
                    "attachmentRenameMode" = "All";
                    "collectAttachmentUsedByMultipleNotesMode" = "Skip";
                    "customTokensStr" = "";
                    "duplicateNameSeparator" = " ";
                    "emptyAttachmentFolderBehavior" = "DeleteWithEmptyParents";
                    "excludePaths" = [ ];
                    "excludePathsFromAttachmentCollecting" = [ ];
                    "generatedAttachmentFileName" = "\${noteFileName}-\${date =YYYYMMDD}";
                    "includePaths" = [ ];
                    "jpegQuality" = 0.8;
                    "markdownUrlFormat" = "";
                    "shouldConvertPastedImagesToJpeg" = false;
                    "shouldDeleteOrphanAttachments" = false;
                    "shouldRenameAttachmentFiles" = true;
                    "shouldRenameAttachmentFolder" = true;
                    "shouldRenameAttachmentsToLowerCase" = false;
                    "shouldRenameCollectedAttachments" = false;
                    "specialCharacters" = "#^[]|*\\<> =?";
                    "specialCharactersReplacement" = "-";
                    "treatAsAttachmentExtensions" = [
                      ".excalidraw.md"
                    ];
                    "warningVersion" = "8.2.2";
                  };
                }
                {
                  pkg = "obsidian-local-images-plus";
                  settings = {
                    "processCreated" = true;
                    "ignoredExt" = "cnt|php|htm|html";
                    "processAll" = true;
                    "useCaptions" = true;
                    "pathInTags" = "fullDirPath";
                    "downUnknown" = false;
                    "saveAttE" = "obsFolder";
                    "realTimeUpdate" = true;
                    "filesizeLimit" = 0;
                    "tryCount" = 2;
                    "realTimeUpdateInterval" = 5;
                    "addNameOfFile" = false;
                    "showNotifications" = true;
                    "include" = ".*\\.md";
                    "mediaRootDir" = "_resources/\${notename}";
                    "disAddCom" = false;
                    "useMD5ForNewAtt" = false;
                    "removeMediaFolder" = true;
                    "removeOrphansCompl" = false;
                    "PngToJpeg" = false;
                    "PngToJpegLocal" = true;
                    "JpegQuality" = 80;
                    "DoNotCreateObsFolder" = false;
                  };
                }
                {
                  pkg = "obsidian-zotero-desktop-connector";
                  settings = {
                    "database" = "Zotero";
                    "noteImportFolder" = "Source Notes";
                    "pdfExportImageDPI" = 120;
                    "pdfExportImageFormat" = "jpg";
                    "pdfExportImageQuality" = 90;
                    "citeFormats" = [
                      {
                        "name" = "Citation Format";
                        "format" = "formatted-citation";
                        "cslStyle" = "apa";
                      }
                    ];
                    "exportFormats" = [
                      {
                        "name" = "Source Notes";
                        "outputPathTemplate" = "Source Notes/{{citekey}}.md";
                        "imageOutputPathTemplate" = " Utilities/Assets/{{citekey}}/";
                        "imageBaseNameTemplate" = "image";
                        "templatePath" = "Utilities/Templates/Source Note.md";
                      }
                    ];
                    "citeSuggestTemplate" = "[[{{citekey}}]]";
                    "openNoteAfterImport" = true;
                    "whichNotesToOpenAfterImport" = "first-imported-note";
                  };
                }
                {
                  pkg = "templater-obsidian";
                  settings = {
                    "command_timeout" = 5;
                    "templates_folder" = "Utilities/Templates";
                    "templates_pairs" = [
                      [
                        ""
                        ""
                      ]
                    ];
                    "trigger_on_file_creation" = false;
                    "auto_jump_to_cursor" = false;
                    "enable_system_commands" = false;
                    "shell_path" = "";
                    "user_scripts_folder" = "";
                    "enable_folder_templates" = true;
                    "folder_templates" = [
                      {
                        "folder" = "";
                        "template" = "";
                      }
                    ];
                    "enable_file_templates" = false;
                    "file_templates" = [
                      {
                        "regex" = ".*";
                        "template" = "";
                      }
                    ];
                    "syntax_highlighting" = true;
                    "syntax_highlighting_mobile" = false;
                    "enabled_templates_hotkeys" = [
                      ""
                    ];
                    "startup_templates" = [
                      ""
                    ];
                    "intellisense_render" = 1;
                  };
                }
              ];
              corePlugins = [
                {
                  name = "bookmarks";
                  settings = {
                    "items" = [
                      {
                        "type" = "group";
                        "ctime" = 1752134167693;
                        "items" = [
                          {
                            "type" = "file";
                            "ctime" = 1752134167693;
                            "path" = "Course Prospectus & Handbook.md";
                            "subpath" = "#^-";
                          }
                          {
                            "type" = "group";
                            "ctime" = 1752134167693;
                            "items" = [
                              {
                                "type" = "file";
                                "ctime" = 1753256442022;
                                "path" = "Module 1/Module 1  Webpage.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1753157360107;
                                "path" = "Module 1/Module 1  Portal.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1753254653008;
                                "path" = "Module 1/Outline.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1753254653008;
                                "path" = "Module 1/Schedule.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1753256795095;
                                "path" = "Module 1/Friday.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1753256795095;
                                "path" = "Module 1/Saturday.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1753256795095;
                                "path" = "Module 1/Sunday.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1753157360107;
                                "path" = "Module 1/Essential Readings - Mal Huxter.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1753157360107;
                                "path" = "Module 1/Essential Readings - Wendy Smith.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1753157360107;
                                "path" = "Module 1/Recommended Readings.md";
                                "subpath" = "#^-";
                              }
                            ];
                            "title" = "Module 1";
                          }
                          {
                            "type" = "group";
                            "ctime" = 1756887868396;
                            "items" = [
                              {
                                "type" = "file";
                                "ctime" = 1756892300735;
                                "path" = "Module 2/Module 2 – PTC7  AABCAP.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1756892300735;
                                "path" = "Module 2/Outline.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1756892300735;
                                "path" = "Module 2/Essential Readings - Subhana Barzarghi.md";
                                "subpath" = "#^-";
                              }
                              {
                                "type" = "file";
                                "ctime" = 1756892300735;
                                "path" = "Module 2/Essential Readings - Subhana Barzarghi.md";
                                "subpath" = "#^-";
                              }
                            ];
                            "title" = "Module 2";
                          }
                          {
                            "type" = "group";
                            "ctime" = 1753157306378;
                            "items" = [ ];
                            "title" = "Source Notes";
                          }
                          {
                            "type" = "group";
                            "ctime" = 1753157306379;
                            "items" = [
                              {
                                "type" = "group";
                                "ctime" = 1752134167693;
                                "items" = [ ];
                                "title" = "Module 1";
                              }
                            ];
                            "title" = "Utilities";
                          }
                        ];
                        "title" = "sortspec";
                      }
                      {
                        "type" = "group";
                        "ctime" = 1752134167693;
                        "items" = [ ];
                        "title" = "Utilities";
                      }
                    ];
                  };
                }
                {
                  name = "templates";
                  settings = {
                    folder = "Utilities/Templates";
                  };
                }
                {
                  name = "workspaces";
                  settings = {
                    "main" = {
                      "id" = "c822dd0737a12f33";
                      "type" = "split";
                      "children" = [
                        {
                          "id" = "27f28e8337510cf2";
                          "type" = "tabs";
                          "children" = [
                            {
                              "id" = "ed4f7ab524901f4a";
                              "type" = "leaf";
                              "state" = {
                                "type" = "markdown";
                                "state" = {
                                  "file" = "Module 2/Readings.md";
                                  "mode" = "source";
                                  "source" = false;
                                };
                                "icon" = "lucide-file";
                                "title" = "Readings";
                              };
                            }
                          ];
                        }
                      ];
                      "direction" = "vertical";
                    };
                    "left" = {
                      "id" = "44a5d5b2cbada32d";
                      "type" = "split";
                      "children" = [
                        {
                          "id" = "3d8e1e42c798a848";
                          "type" = "tabs";
                          "children" = [
                            {
                              "id" = "8cdaa6537d6fd2eb";
                              "type" = "leaf";
                              "state" = {
                                "type" = "file-explorer";
                                "state" = {
                                  "sortOrder" = "alphabetical";
                                  "autoReveal" = false;
                                };
                                "icon" = "lucide-folder-closed";
                                "title" = "Files";
                              };
                            }
                            {
                              "id" = "3e763f30d69f23b7";
                              "type" = "leaf";
                              "state" = {
                                "type" = "search";
                                "state" = {
                                  "query" = "";
                                  "matchingCase" = false;
                                  "explainSearch" = false;
                                  "collapseAll" = false;
                                  "extraContext" = false;
                                  "sortOrder" = "alphabetical";
                                };
                                "icon" = "lucide-search";
                                "title" = "Search";
                              };
                            }
                            {
                              "id" = "5e67398fc65a2da9";
                              "type" = "leaf";
                              "state" = {
                                "type" = "bookmarks";
                                "state" = { };
                                "icon" = "lucide-bookmark";
                                "title" = "Bookmarks";
                              };
                            }
                          ];
                        }
                      ];
                      "direction" = "horizontal";
                      "width" = 344.50390243530273;
                    };
                    "right" = {
                      "id" = "ac6b23bc1ed5fbf3";
                      "type" = "split";
                      "children" = [
                        {
                          "id" = "03e9a4d65c608b69";
                          "type" = "tabs";
                          "children" = [
                            {
                              "id" = "9612c18a1c8903e7";
                              "type" = "leaf";
                              "state" = {
                                "type" = "backlink";
                                "state" = {
                                  "file" = "Course Overview.md";
                                  "collapseAll" = false;
                                  "extraContext" = false;
                                  "sortOrder" = "alphabetical";
                                  "showSearch" = false;
                                  "searchQuery" = "";
                                  "backlinkCollapsed" = false;
                                  "unlinkedCollapsed" = true;
                                };
                                "icon" = "links-coming-in";
                                "title" = "Backlinks for Course Overview";
                              };
                            }
                            {
                              "id" = "71149da778f1c48f";
                              "type" = "leaf";
                              "state" = {
                                "type" = "outgoing-link";
                                "state" = {
                                  "file" = "Course Overview.md";
                                  "linksCollapsed" = false;
                                  "unlinkedCollapsed" = true;
                                };
                                "icon" = "links-going-out";
                                "title" = "Outgoing links from Course Overview";
                              };
                            }
                            {
                              "id" = "e6bdde37f91e6bb8";
                              "type" = "leaf";
                              "state" = {
                                "type" = "tag";
                                "state" = {
                                  "sortOrder" = "frequency";
                                  "useHierarchy" = true;
                                  "showSearch" = false;
                                  "searchQuery" = "";
                                };
                                "icon" = "lucide-tags";
                                "title" = "Tags";
                              };
                            }
                            {
                              "id" = "474724766b3ce944";
                              "type" = "leaf";
                              "state" = {
                                "type" = "outline";
                                "state" = {
                                  "file" = "Course Overview.md";
                                  "followCursor" = false;
                                  "showSearch" = false;
                                  "searchQuery" = "";
                                };
                                "icon" = "lucide-list";
                                "title" = "Outline of Course Overview";
                              };
                            }
                          ];
                        }
                      ];
                      "direction" = "horizontal";
                      "width" = 300;
                      "collapsed" = true;
                    };
                    "left-ribbon" = {
                      "hiddenItems" = {
                        "bases =Create new base" = false;
                        "obsidian-local-images-plus =Local Images Plus  0.16.3\r\nLocalize attachments (plugin folder)" =
                          false;
                        "custom-sort =Toggle custom sorting" = false;
                        "switcher =Open quick switcher" = false;
                        "graph =Open graph view" = false;
                        "canvas =Create new canvas" = false;
                        "daily-notes =Open today's daily note" = false;
                        "templates =Insert template" = false;
                        "command-palette =Open command palette" = false;
                        "templater-obsidian =Templater" = false;
                      };
                    };
                    "active" = "ed4f7ab524901f4a";
                    "lastOpenFiles" = [
                      "Utilities/Assets/Module 2/Readings/Readings-20250903.pdf"
                      "Module 2/Readings.md"
                      "Utilities/Assets/Module 2/Readings/~$adings-20250919 1.docx"
                      "Utilities/Assets/Module 2/Readings/Readings-20250919 2.docx"
                      "Utilities/Assets/Module 2/Readings/Kristin-Neff-Self-Compassion-Scale (local link).docx"
                      "Utilities/Assets/Module 2/Readings/~$adings-20250919.docx"
                      "Module 2/Outline.md"
                      "Utilities/Assets/Module 2/Readings/M2-Empathy-fatigue-Burnout-VC (local link).docx"
                      "Module 2/Module 2 – PTC7  AABCAP.md"
                      "Module 1/Module 1  Webpage.md"
                      "Module 1/Recommended Readings.md"
                      "Module 1/Essential Readings - Mal Huxter.md"
                      "Module 1/Essential Readings - Wendy Smith.md"
                      "Utilities/Assets/Module 2/Readings"
                      "Module 2/Essential Readings - Subhana Barzarghi.md"
                      "Module 1/Schedule.md"
                      "Utilities/Assets/Module 2/Outline/Outline-20250903.pdf"
                      "Utilities/Assets/Module 2/Outline"
                      "Utilities/Assets/Module 2/Module 2 – PTC7  AABCAP"
                      "Utilities/Assets/Module 1/Module 1  Webpage/c61523524869b85ae6e42eabadb5a262_MD5.gif"
                      "Utilities/Assets/Module 1/Module 1  Webpage/c187d0ee5df5c856389ccca1430b6345_MD5.png"
                      "Module 1/Friday.md"
                      "Module 1/Outline.md"
                      "Module 1/Sunday.md"
                      "Module 1/Saturday.md"
                      "Module 1/Module 1  Portal.md"
                      "Module 1/Protected Class Space  AABCAP.md"
                      "Clippings/Protected Module 1  AABCAP.md"
                      "Utilities/Templates/Source Note.md"
                      "Course Prospectus & Handbook.md"
                    ];
                  };
                }
              ]
              ++ [
                "audio-recorder"
                "backlink"
                "bases"
                "canvas"
                "command-palette"
                "daily-notes"
                "editor-status"
                "file-explorer"
                "file-recovery"
                "footnotes"
                "global-search"
                "graph"
                "markdown-importer"
                "note-composer"
                "outgoing-link"
                "outline"
                "page-preview"
                "properties"
                "publish"
                "random-note"
                "slash-command"
                "slides"
                "switcher"
                "sync"
                "tag-pane"
                "webviewer"
                "word-count"
                "zk-prefixer"
              ];
              hotkeys = {
                "obsidian-zotero-desktop-connector:zdc-exp-Source Notes" = [
                  {
                    modifiers = [
                      "Mod"
                      "Shift"
                    ];
                    key = "L";
                  }
                ];
              };
            };
          };
        };
      };
    };
  };
}
