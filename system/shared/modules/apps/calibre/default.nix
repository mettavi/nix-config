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
    nixpkgs.overlays = [
      (final: prev: {
        calibre = prev.calibre.overrideAttrs (old: {
          # skip calibre tests in GitHub workflows (see nix.yml)
          doCheck = (builtins.getEnv "SKIP_CALIBRE_TESTS") != "1";
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
          copy-calibre-plugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
