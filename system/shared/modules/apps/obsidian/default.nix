{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.apps.obsidian;
  jsonFormat = pkgs.formats.json { };
  emptyPinnedVaultSettings = {
    app = null;
    appearance = null;
    hotkeys = null;
    corePlugins = { };
    plugins = { };
    files = { };
  };
  pinnedVaultSettingsSubmodule = types.submodule {
    options = {
      app = mkOption {
        type = types.nullOr jsonFormat.type;
        default = null;
        description = "Keys merged into app.json.";
      };
      appearance = mkOption {
        type = types.nullOr jsonFormat.type;
        default = null;
        description = "Keys merged into appearance.json.";
      };
      hotkeys = mkOption {
        type = types.nullOr jsonFormat.type;
        default = null;
        description = "Keys merged into hotkeys.json.";
      };
      corePlugins = mkOption {
        type = types.attrsOf jsonFormat.type;
        default = { };
        description = "Core plugin name -> keys merged into its <name>.json.";
      };
      plugins = mkOption {
        type = types.attrsOf jsonFormat.type;
        default = { };
        description = "Community plugin manifest id -> keys merged into its data.json.";
      };
      files = mkOption {
        type = types.attrsOf jsonFormat.type;
        default = { };
        description = "Path relative to .obsidian/ -> keys merged into that JSON file.";
      };
    };
  };
  # null-safe recursive merge: b wins on leaf conflicts, missing side treated as {}
  mergeMaybe =
    a: b:
    if a == null && b == null then
      null
    else
      lib.recursiveUpdate (if a == null then { } else a) (if b == null then { } else b);

  # merge two full pinned-settings records: `override` wins over `base`,
  # recursing into corePlugins/plugins/files per-key (and into each
  # entry's own keys, since recursiveUpdate recurses through nested attrsets)
  mergePinned = base: override: {
    app = mergeMaybe base.app override.app;
    appearance = mergeMaybe base.appearance override.appearance;
    hotkeys = mergeMaybe base.hotkeys override.hotkeys;
    corePlugins = lib.recursiveUpdate base.corePlugins override.corePlugins;
    plugins = lib.recursiveUpdate base.plugins override.plugins;
    files = lib.recursiveUpdate base.files override.files;
  };
in
{
  options.mettavi.apps.obsidian = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure Obsidian";
    };
    vaultsParent = mkOption {
      type = types.str;
      default = "Documents/Obsidian";
      description = "Where the Obsidian vaults are saved";
    };
    pinnedDefaultSettings = mkOption {
      type = pinnedVaultSettingsSubmodule;
      default = { };
      description = ''
        Settings merged into every enabled vault's live config files.
        Per-vault entries in `pinnedSettings` are recursively merged on
        top of this — a vault only needs to declare what it wants to
        add or change, not repeat the shared baseline.
      '';
    };
    pinnedSettings = mkOption {
      type = types.attrsOf pinnedVaultSettingsSubmodule;
      default = { };
      description = ''
        Per-vault overrides/additions on top of `pinnedDefaultSettings`,
        keyed by the same vault path used in `programs.obsidian.vaults`.
        Merged (via jq) into the live, GUI-editable Obsidian config
        files rather than replacing them outright. Do not also set
        `programs.obsidian.vaults.<name>.settings.<x>` for the same
        file/plugin — the plain Nix-managed symlink wins on the next
        activation and your merged patch is discarded.
      '';
    };
  };

  config = mkIf cfg.enable {
    # enable pkgs.obsidianPlugins and pkgs.obsidianThemes from the obsidian-extensions flake
    nixpkgs.overlays = [
      inputs.obsidian-extensions.overlays.default
    ];

    # any settings included here will be MERGED by an activation script along with any values set by the GUI
    mettavi.apps.obsidian = {
      pinnedDefaultSettings = {
        app = {
          alwaysUpdateLinks = true;
          spellcheck = true;
        };
        corePlugins.templates.folder = "Utilities/Templates"; # flat file — safe to pin
      };
      pinnedSettings = {
        # "${cfg.vaultsParent}/Evernote" = {
        # bookmarks = { ... };  # DON'T — bookmarks.json is essentially one big
        # `items` array; pinning anything here would
        # wipe out GUI-added bookmarks on next rebuild.
        # Leave bookmarks.json out of both `corePlugins`
        # here and `programs.obsidian...corePlugins`
        # entirely if you want it GUI-owned.
        # };
        # };
        # "${cfg.vaultsParent}/Personal Notes" = {
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

    home-manager.users.${username} =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        assertions =
          lib.mapAttrsToList (vaultName: vaultCfg: {
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
          }) cfg.pinnedSettings
          ++ (
            let
              obsidianVaults = config.programs.obsidian.vaults;
              effectiveFor =
                vaultName:
                mergePinned cfg.pinnedDefaultSettings (cfg.pinnedSettings.${vaultName} or emptyPinnedVaultSettings);
            in
            lib.mapAttrsToList (vaultName: vaultCfg: {
              assertion =
                let
                  declaredCore = obsidianVaults.${vaultName}.settings.corePlugins or null;
                  pinnedCoreNames = lib.attrNames (effectiveFor vaultName).corePlugins;
                  declaredWithSettings = lib.optionals (declaredCore != null) (
                    map (p: p.name) (builtins.filter (p: p.settings != null) declaredCore)
                  );
                in
                lib.intersectLists pinnedCoreNames declaredWithSettings == [ ];
              message = "mettavi.apps.obsidian: vault \"${vaultName}\" has core plugin(s) [${
                lib.concatStringsSep ", " (
                  lib.intersectLists (lib.attrNames (effectiveFor vaultName).corePlugins) (
                    map (p: p.name) (
                      builtins.filter (p: p.settings != null) (obsidianVaults.${vaultName}.settings.corePlugins or [ ])
                    )
                  )
                )
              }] both pinned and declared with `settings` — pick one mechanism per plugin.";
            }) obsidianVaults
          )
          ++ [
            {
              assertion = lib.all (
                vaultName: builtins.hasAttr vaultName config.home-manager.users.${username}.programs.obsidian.vaults
              ) (lib.attrNames cfg.pinnedSettings);
              message = "mettavi.apps.obsidian.pinnedSettings has an entry for a vault not declared in programs.obsidian.vaults — check for a typo in the path.";
            }
          ];

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

            enabledVaultNames = lib.attrNames (
              lib.filterAttrs (_: v: v.enable) config.programs.obsidian.vaults
            );

            effectiveFor =
              vaultName:
              mergePinned cfg.pinnedDefaultSettings (cfg.pinnedSettings.${vaultName} or emptyPinnedVaultSettings);

            mkVaultPatches =
              vaultName:
              let
                obsidianDir = "${config.home.homeDirectory}/${vaultName}/.obsidian";
                vaultCfg = effectiveFor vaultName;
              in
              lib.concatStrings (
                lib.optional (vaultCfg.app != null) (mkPatch "${obsidianDir}/app.json" vaultCfg.app)
                ++ lib.optional (vaultCfg.appearance != null) (
                  mkPatch "${obsidianDir}/appearance.json" vaultCfg.appearance
                )
                ++ lib.optional (vaultCfg.hotkeys != null) (mkPatch "${obsidianDir}/hotkeys.json" vaultCfg.hotkeys)
                ++ lib.mapAttrsToList (
                  name: values: mkPatch "${obsidianDir}/${name}.json" values
                ) vaultCfg.corePlugins
                ++ lib.mapAttrsToList (
                  pluginId: values: mkPatch "${obsidianDir}/plugins/${pluginId}/data.json" values
                ) vaultCfg.plugins
                ++ lib.mapAttrsToList (relPath: values: mkPatch "${obsidianDir}/${relPath}" values) vaultCfg.files
              );
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] (
            lib.concatStrings (map mkVaultPatches enabledVaultNames)
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
            # Plugin attributes use the IDs from the official Obsidian plugin registry.
            # They do not always match the display names shown in Obsidian.
            # Check ${pkgs.obsidianPlugins.foo}/manifest.json's id field,
            # or just look at the folder once the plugin's installed.
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
            "${cfg.vaultsParent}/Evernote" = {
              enable = true;
            };
            "${cfg.vaultsParent}/AABCAP 2025-26" = {
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
