{
  lib,
  pkgs,
  ...
}:
with lib;
{
  imports = [ ./zotero.nix ];

  dconf.settings = {
    # add custom keybindings for ASUS linux utilities
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "ROG Control Center";
      command = "rog-control-center";
      # on the keyboard this is the M4 key
      binding = "Launch1";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Next Power Mode";
      command = "asusctl profile next";
      # on the main keyboard this is Fn-F5
      binding = "Launch4";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "Next Aura Mode";
      command = "asusctl leds next";
      # on the main keyboard this is Fn-F4
      binding = "Launch3";
    };
    "org/gnome/shell" = {
      # `gnome-extensions list` for a list
      enabled-extensions = [
        "gpu-switcher-supergfxctl@chikobara.github.io"
      ];
    };
  };
  home = {
    packages = with pkgs; [
      # Simple GPU Profile switcher for ASUS laptops using Supergfxctl
      gnomeExtensions.gpu-supergfxctl-switch
      goldendict-ng # Advanced multi-dictionary lookup program
      gramps # Genealogy software
    ];
    sessionVariables = {
      # required for electron apps, which don't read the mimeapps.list file
      DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
    };
    stateVersion = "25.11";
  };
  # install the HTML manual and "home-manager-help" command
  manual.html.enable = true;

  mettavi = {
    apps = {
      anki.enable = true;
      firefox.enable = true;
      ghostty.enable = true;
      obsidian.enable = true;
    };
    shell = {
      bash.enable = true;
      nh.enable = true;
      tmux.enable = true;
      yazi.enable = true;
      # zsh is enabled by default
    };
  };

  xdg.mimeApps = {
    enable = true;
    /*
      To list all .desktop files, run:
      ls /run/current-system/sw/share/applications # for global packages
      ls /etc/profiles/per-user/$(id -n -u)/share/applications # for user packages
    */
    # See http://discourse.nixos.org/t/how-can-i-configure-the-default-apps-for-gnome/36034
    defaultApplications = {
      # gnome image viewer
      "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
      # gnome document viewer
      "application/pdf" = [ "org.gnome.Evince.desktop" ];
    }
    // mkIf mettavi.apps.firefox.enable {
      "default-web-browser" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };
}
