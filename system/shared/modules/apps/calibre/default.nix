{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.mettavi.system.apps.calibre;
in
{
  imports = [ ./calibre-and-sync.nix ];

  options.mettavi.system.apps.calibre = {
    enable = lib.mkEnableOption "Install and set up the calibre ebook manager";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} =
      { osConfig, ... }:
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
        home.packages = with pkgs; [
          # Comprehensive e-book software
          (calibre.override {
            # to open .cbr and .cbz files
            unrarSupport = true;
          })
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
