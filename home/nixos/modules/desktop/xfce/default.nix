{
  config,
  lib,
  ...
}:
let
  cfg = config.nyx.modules.desktop.xfce;
in
{
  options.nyx.modules.desktop.xfce = {
    enable = lib.mkEnableOption "Configure XFCE Desktop";
  };

  config = lib.mkIf cfg.enable {
    xfconf = {
      enable = true;
      settings = {
        displays = {
          "Default/Virtual-1/Scale" = 0.666656;
        };
        xsettings = {
          "Gtk/FontName" = "Sans 12";
          "Gtk/MonospaceFontName" = "Monospace 12";
        };
        xfce4-panel = {
          # always autohide the top panel (taskbar)
          # 2 = always, 1 = intelligent, 0 = never
          "panels/panel-1/autohide-behavior" = 2;
        };
        xfce4-screensaver = {
          "lock/saver-activation/enabled" = false;
        };
      };
    };
  };
}
