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
    cal_lib = lib.mkOption {
      description = "The location of the calibre library in the filesystem";
      type = lib.types.path;
      default = "${config.users.users.${username}.home}/Documents/calibre";
    };
  };

  config = lib.mkIf cfg.enable {
    # skip calibre tests in GitHub workflows (see nix.yml)
    nixpkgs.overlays = [
      (final: prev: {
        calibre = prev.calibre.overrideAttrs (old: {
          doCheck = (builtins.getEnv "SKIP_CALIBRE_TESTS") != "1";
        });
      })
    ];

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
          # TODO: The override is not working as at 2/9/2026
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
