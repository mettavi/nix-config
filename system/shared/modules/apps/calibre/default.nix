{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.mettavi.system.apps.calibre;
  syncBooksScript = pkgs.writeShellApplication {
    name = "sync-books";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      openssh
      rsync
    ];
    text = # bash
      ''
        DRY_RUN=false
        RSYNC_EXTRA_FLAGS=()

        for arg in "$@"; do
          case "$arg" in
            -n|--dry-run)
              DRY_RUN=true
              RSYNC_EXTRA_FLAGS+=(--dry-run --stats)
              ;;
            *)
              echo "Usage: sync-books [-n|--dry-run]" >&2
              exit 1
              ;;
          esac
        done

        CALIBRE_DIR="$HOME/media/calibre"
        REMOTE_HOST="timotheos@apps.mettavi.cloud"
        REMOTE_DIR="/srv/media/ebooks/"
        CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}"
        EXCLUDE_FILE="$CACHE_DIR/calibre-rsync-exclude.txt"

        mkdir -p "$CACHE_DIR"

        echo "Building duplicate azw3/mobi exclusion list..."
        : > "$EXCLUDE_FILE"
        while IFS= read -r -d "" epub; do
          dir="$(dirname "$epub")"
          find "$dir" -maxdepth 1 -type f \( -iname '*.azw3' -o -iname '*.mobi' \) -print0 \
            | xargs -0 -r realpath --relative-to="$CALIBRE_DIR" >> "$EXCLUDE_FILE"
        done < <(find "$CALIBRE_DIR" -type f -name '*.epub' -print0)
        sort -u -o "$EXCLUDE_FILE" "$EXCLUDE_FILE"

        if [ "$DRY_RUN" = true ]; then
          echo "Running DRY RUN sync to $REMOTE_HOST..."
        else
          echo "Syncing Calibre library to $REMOTE_HOST..."
        fi

        rsync -avh --omit-dir-times --progress --partial \
          "''${RSYNC_EXTRA_FLAGS[@]}" \
          --exclude-from="$EXCLUDE_FILE" \
          --exclude='metadata.db' \
          --exclude='full-text-search.db' \
          --exclude='metadata_db_prefs_backup.json' \
          --exclude='.caltrash/' \
          --exclude='.DS_Store' \
          --exclude='*.original_*' \
          --exclude='*.mbp' \
          --exclude='*.pdr' \
          --exclude='*.xtra' \
          --max-size='50M' \
          --no-owner --no-group --chmod=D2770,F660 \
          "$CALIBRE_DIR/" "$REMOTE_HOST:$REMOTE_DIR"

        if [ "$DRY_RUN" = true ]; then
          echo "Dry run complete. Skipping remote update-bookorbit-opf."
        else
          echo "Updating BookOrbit OPF tags and page counts on remote server..."
          ssh "$REMOTE_HOST" "update-bookorbit-opf"
        fi
      '';
  };
in
{
  imports = [ ./calibre-and-sync.nix ];

  options.mettavi.system.apps.calibre = {
    enable = mkEnableOption "Install and set up the calibre ebook manager";
    cal_lib = mkOption {
      description = "The location of the calibre library in the filesystem";
      type = path;
      default = "${config.users.users.${username}.home}/Documents/calibre";
    };
    plugins = mkOption {
      type = listOf package;
      default = with pkgs.xpkgs.calibrePlugins; [
        acsm # Calibre plugin for ACSM->EPUB and ACSM->PDF conversion
        annotations
        extract-isbn
      ];
      description = "A list of calibre plugins to install";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ syncBooksScript ];

    nixpkgs.overlays = [
      (final: prev: {
        calibre = prev.calibre.overrideAttrs (old: {
          # Calibre 9.15.0's FTS tests are currently unstable/known-bad in this
          # environment, so don't run them during package builds.
          doCheck = false;
        });
      })
    ];

    home-manager.users.${username} =
      {
        config,
        lib,
        osConfig,
        ...
      }:
      let
        pluginZip = plugin: "${plugin}/${plugin.pluginZip}";
      in
      {
        dconf.settings = lib.mkIf osConfig.mettavi.system.desktops.gnome.enable {
          "org/gnome/desktop/app-folders" = {
            folder-children = [
              "Calibre"
            ];
          };
          "org/gnome/desktop/app-folders/folders/Calibre" = {
            name = "Calibre";
            apps = [
              "calibre-gui.desktop"
              "CaliSync.desktop"
              "calibre-ebook-viewer.desktop"
              "calibre-ebook-edit.desktop"
              "calibre-lrfviewer.desktop"
            ];
            translate = false;
          };
        };
        home.activation = {
          # adapted with thanks from:
          # https://github.com/jwillikers/media-juggler/blob/95cda525b82ce38b6802443bbedd67fbcfabeef1/home-manager-module.nix
          copy-calibre-plugins =
            lib.hm.dag.entryAfter [ "writeBoundary" ] # bash
              ''
                # calibre-customize initializes every installed plugin before it processes
                # --add-plugin. If the old ACSM Input zip is still installed, its
                # oscrypto.use_openssl() call records the old openssl paths, and the new
                # copy's call (new paths) then fails with "Another part of oscrypto has
                # already been imported". Removing only the zip avoids that. add_plugin
                # deletes and re-copies it anyway, so this costs nothing. Leave ACSMInput/
                # alone, because it holds account/ (your Adobe authorization).
                rm -f ${lib.escapeShellArg "${config.xdg.configHome}/calibre/plugins/ACSM Input.zip"}
                ${lib.concatMapStringsSep "\n" (plugin: ''
                  ${pkgs.calibre}/bin/calibre-customize --add-plugin=${lib.escapeShellArg (pluginZip plugin)}
                '') cfg.plugins}
                  chmod +w ${lib.escapeShellArg config.xdg.configHome}/calibre/plugins/*.zip
              '';
        };
        home.packages = with pkgs; [
          # TODO: Fixed in https://github.com/NixOS/nixpkgs/pull/558309 on 10-09-26
          # See https://github.com/NixOS/nixpkgs/issues/559101 for more details

          # Comprehensive e-book software
          # (calibre.override {
          # to open .cbr and .cbz files
          #   unrarSupport = true;
          # })
          calibre
        ];

        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "application/lrf" = "calibre-lrfviewer.desktop";
            "application/epub+zip" = "calibre-ebook-viewer.desktop";
          };
        };
      };
  };
}
