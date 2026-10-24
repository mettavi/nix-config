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
  # prevent errors if pinned settings is empty
  emptyPinnedVaultSettings = {
    app = null;
    appearance = null;
    files = { };
    folders = [ ];
    hotkeys = null;
    communityPlugins = { };
    corePlugins = { };
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
      # Plugin attributes use the IDs from the official Obsidian plugin registry.
      # They do not always match the display names shown in Obsidian.
      # Check ${pkgs.obsidianPlugins.foo}/manifest.json's id field,
      # or just look at the folder once the plugin is installed.
      communityPlugins = mkOption {
        type = types.attrsOf jsonFormat.type;
        default = { };
        description = "Community plugin manifest id -> keys merged into its data.json.";
      };
      corePlugins = mkOption {
        type = types.attrsOf jsonFormat.type;
        default = { };
        description = "Core plugin name -> keys merged into its <name>.json.";
      };
      # used for non-standard settings files, such as files which are not tied to a plugin
      # (eg. types.json, for property types in front matter)
      # or perhaps a second JSON file belonging to a plugin (not stored in data.json)
      files = mkOption {
        type = types.attrsOf jsonFormat.type;
        default = { };
        description = "Per-vault path relative to .obsidian/ -> keys merged into that JSON file.";
      };
      folders = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Folders (relative to the vault root) to create if missing.";
      };
      hotkeys = mkOption {
        type = types.nullOr jsonFormat.type;
        default = null;
        description = "Keys merged into hotkeys.json.";
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
    communityPlugins = lib.recursiveUpdate base.communityPlugins override.communityPlugins;
    corePlugins = lib.recursiveUpdate base.corePlugins override.corePlugins;
    files = lib.recursiveUpdate base.files override.files;
    folders = lib.unique (base.folders ++ override.folders);
    hotkeys = mergeMaybe base.hotkeys override.hotkeys;
  };

  vaults = {
    evernote = "${cfg.vaultsParent}/Evernote";
    myNotes = "${cfg.vaultsParent}/myNotes";
  };
in
{
  options.mettavi.apps.obsidian = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure Obsidian";
    };
    enabledCommunityPlugins = {
      default = mkOption {
        type = types.listOf types.package;
        default = with pkgs.obsidianPlugins; [
          obsidian-style-settings # user interface for adjusting theme, plugin, and snippet CSS variables
          omnisearch
        ];
        description = "Community plugins enabled in every vault.";
      };
      perVault = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              add = mkOption {
                type = types.listOf types.package;
                default = [ ];
              };
              remove = mkOption {
                type = types.listOf types.package;
                default = [ ];
              };
            };
          }
        );
        default = { };
        description = "Per-vault additions and removals, keyed by vault path.";
      };
    };
    enabledCorePlugins = {
      default = mkOption {
        type = types.listOf types.str;
        # Core plugins omitted from this list are disabled.
        default = [
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
        description = "Core plugins enabled in every vault.";
      };
      perVault = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              add = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
              remove = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
            };
          }
        );
        default = { };
        description = "Per-vault additions and removals, keyed by vault path.";
      };
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
    vaultsParent = mkOption {
      type = types.str;
      default = "Documents/Obsidian";
      description = "Where the Obsidian vaults are saved";
    };
  };

  config = mkIf cfg.enable {
    # enable pkgs.obsidianPlugins and pkgs.obsidianThemes from the obsidian-extensions flake
    nixpkgs.overlays = [
      inputs.obsidian-extensions.overlays.default
    ];

    # NB: any settings included here will be MERGED by an activation script along with any values set by the GUI
    mettavi.apps.obsidian = {
      enabledCommunityPlugins.perVault = {
        ${vaults.evernote}.add = with pkgs.obsidianPlugins; [
          obsidian-importer
        ];
      };
      # Settings merged into every enabled vault's live config files
      pinnedDefaultSettings = {
        app = {
          alwaysUpdateLinks = true;
          spellcheck = true;
          promptDelete = false;
          showUnsupportedFiles = true;
        };
        corePlugins = {
          templates.folder = "Utilities/Templates"; # flat file — safe to pin
        };
        folders = [
          "Utilities/Templates"
        ];
      };
      # Per-vault overrides/additions on top of `pinnedDefaultSettings`
      pinnedSettings = {
        ${vaults.myNotes} = {
          app = {
            # whether to limit maximum line length
            readableLineLength = false;
          };
        };
        # ${vaults.evernote} = {
        # corePlugins.bookmarks = { ... };  # DON'T — bookmarks.json is essentially one big
        # `items` array; pinning anything here would
        # wipe out GUI-added bookmarks on next rebuild.
        # Leave bookmarks.json out of both `corePlugins`
        # here and `programs.obsidian...corePlugins`
        # entirely if you want it GUI-owned.
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
                declared = config.programs.obsidian.vaults.${vaultName}.settings or null;
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
                vaultName: builtins.hasAttr vaultName config.programs.obsidian.vaults
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
                echo "obsidian: patching $target"
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
                vaultRoot = "${config.home.homeDirectory}/${vaultName}";
              in
              lib.concatStrings (
                (map (folder: ''
                  mkdir -p ${lib.escapeShellArg "${vaultRoot}/${folder}"}
                '') vaultCfg.folders)
                ++ lib.optional (vaultCfg.app != null) (mkPatch "${obsidianDir}/app.json" vaultCfg.app)
                ++ lib.optional (vaultCfg.appearance != null) (
                  mkPatch "${obsidianDir}/appearance.json" vaultCfg.appearance
                )
                ++ lib.optional (vaultCfg.hotkeys != null) (mkPatch "${obsidianDir}/hotkeys.json" vaultCfg.hotkeys)
                ++ lib.mapAttrsToList (
                  name: values: mkPatch "${obsidianDir}/${name}.json" values
                ) vaultCfg.corePlugins
                ++ lib.mapAttrsToList (
                  pluginId: values: mkPatch "${obsidianDir}/plugins/${pluginId}/data.json" values
                ) vaultCfg.communityPlugins
                ++ lib.mapAttrsToList (relPath: values: mkPatch "${obsidianDir}/${relPath}" values) vaultCfg.files
              );
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] (
            lib.concatStrings (map mkVaultPatches enabledVaultNames)
          );

        # install the firefox extension
        programs.firefox.profiles."mettavi".extensions.packages =
          with pkgs.nur.repos.rycee.firefox-addons;
          optionals (config.mettavi.apps.firefox.enable) [ web-clipper-obsidian ];

        # NB: Any plugin's settings configured here
        # will overwrite ALL its GUI-configured settings (if set)
        # Prefer the pinnedDefaultSettings and pinnedSettings options, which are more flexible
        programs.obsidian = {
          enable = true;
          # NB: Vault-specific settings take priority and will REPLACE (not merge) these, if set.
          defaultSettings = {
            communityPlugins = cfg.enabledCommunityPlugins.default;
            corePlugins = cfg.enabledCorePlugins.default;
            # BARE PACKAGE (COERCED TO { PKG = P; }): SETTINGS DEFAULTS TO NULL.
            # -> INSTALLED + ENABLED VIA NIX, DATA.JSON FULLY GUI-MANAGED.
            # omnisearch
            # SAME THING, SPELLED OUT, PLUS EXPLICIT ENABLE CONTROL:
            # {
            #   pkg = pkgs.obsidianPlugins.templater-obsidian;
            #   enable = true;
            # no `settings` key here -> data.json is GUI territory
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
            themes = with pkgs.obsidianThemes; [
              catppuccin
            ];
          };
          # Settings for any attribute here will replace ALL those set through the GUI;
          # Omit them here to set via the GUI and/or merge any desired settings
          # with `mettavi.apps.obsidian.pinnedSettings` (see above) instead.
          vaults = lib.mkMerge [
            # 1. Hand-written vault definitions
            {
              # inherit most of the settings from pinnedDefaultSettings
              ${vaults.evernote} = {
                enable = true;
              };
              ${vaults.myNotes} = {
                enable = true;
              };
            }
            # 2. Generated: core plugin list per vault
            (lib.mapAttrs (_: v: {
              settings.corePlugins = (lib.subtractLists v.remove cfg.enabledCorePlugins.default) ++ v.add;
            }) cfg.enabledCorePlugins.perVault)

            # 3. Generated: community plugin list per vault
            (lib.mapAttrs (_: v: {
              settings.communityPlugins =
                (lib.subtractLists v.remove cfg.enabledCommunityPlugins.default) ++ v.add;
            }) cfg.enabledCommunityPlugins.perVault)
          ];
        };
      };
  };
}
