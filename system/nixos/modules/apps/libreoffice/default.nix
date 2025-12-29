{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  office = pkgs.libreoffice-fresh-unwrapped;
  cfg = config.mettavi.system.apps.libreoffice;
in
{
  options.mettavi.system.apps.libreoffice = {
    enable = lib.mkEnableOption "Install and set up libreoffice suite";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      dconf.settings = lib.mkIf config.mettavi.system.desktops.gnome.enable {
        # organise the apps menu into folders
        "org/gnome/desktop/app-folders" = {
          folder-children = [
            "LibreOffice"
          ];
        };
        "org/gnome/desktop/app-folders/folders/LibreOffice" = {
          name = "LibreOffice";
          apps = [
            "startcenter.desktop"
            "writer.desktop"
            "impress.desktop"
            "math.desktop"
            "base.desktop"
            "calc.desktop"
            "draw.desktop"
          ];
          translate = false;
        };
      };
    };
    environment.systemPackages = with pkgs; [
      libreoffice-fresh
      hunspell
      hunspellDicts.en_AU
      hunspellDicts.en_US
      hyphenDicts.en_US
    ];
    environment.sessionVariables = {
      PYTHONPATH = "${office}/lib/libreoffice/program";
      URE_BOOTSTRAP = "vnd.sun.star.pathname:${office}/lib/libreoffice/program/fundamentalrc";
    };
  };
}
