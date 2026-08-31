{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.mettavi.system.apps.liboffice-lite;
in
{
  options.mettavi.system.apps.liboffice-lite = {
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
            "calc.desktop"
            "math.desktop"
            "base.desktop"
            "draw.desktop"
          ];
          translate = false;
        };
      };
      xdg.mimeApps.defaultApplications = {
        "application/vnd.oasis.opendocument.text" = [ "writer.desktop" ];
      };
    };
    environment.systemPackages = with pkgs; [
      # gtk version (the kdeIntegration variable defaults to false)
      libreoffice-stable
      hunspell
      hunspellDicts.en_AU
      hunspellDicts.en_US
      hyphenDicts.en_US
      # MS fonts
      corefonts
      vista-fonts
    ];
  };
}
