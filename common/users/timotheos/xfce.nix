{ username, ... }:
{
  home-manager.users.${username} = {
    xfconf = {
      enable = true;
      settings = {
        displays = {
          "Default/Virtual-1/Scale" = 0.571426;
        };
        xsettings = {
          "Gtk/FontName" = "Sans 12";
          "Gtk/MonospaceFontName" = "Monospace 12";
        };
        xfce4-screensaver = {
          "lock/saver-activation/enabled" = false;
        };
      };
    };
  };
}
