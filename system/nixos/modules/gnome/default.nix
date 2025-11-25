{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.gnome;
in
{
  options.mettavi.system.gnome = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable and configure the gnome desktop environment on the system";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      gnome.excludePackages = with pkgs; [
        gnome-console # terminal emulator for the GNOME desktop
        gnome-tour
        epiphany # web broswer (aka "Gnome Web")
      ];
      systemPackages =
        (with pkgs; [ celluloid ]) # GTK frontend for the mpv video player
        ++ (with pkgs.gst_all_1; [
          # GSTREAMER PLUGINS
          gst-plugins-base
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav # FFmpeg plugin for GStreamer
          gst-vaapi # Set of VAAPI GStreamer Plug-ins
        ]);
      # ++ (with pkgs.gnomeExtensions; [
      #   app-icons-taskbar
      #   appindicator
      # ]);
      variables = {
        # Allow apps such as Gnome Files (Nautilus) to detect gstreamer plugins
        GST_PLUGIN_PATH_1_0 = [ "/run/current-system/sw/lib/gstreamer-1.0" ];
      };
    };
    services = {
      # install GNOME using wayland
      displayManager.gdm.enable = lib.mkDefault true;
      desktopManager.gnome.enable = true;
      gnome = {
        # allow to install GNOME Shell extensions from a web browser
        gnome-browser-connector.enable = true;
        # authorise file sharing with other devices
        gnome-user-share.enable = true;
      };
    };
    users.users.root = {
      # add apps for root to use for troubleshooting (as the eqivalent gnome builtin apps have been removed system wide)
      packages = with pkgs; [
        firefox
        ghostty
      ];
    };

    home-manager.users.${username} = {
      home.packages =
        (with pkgs; [
          dconf-editor # GSettings editor for GNOME
          gnome-extension-manager # Desktop app for managing GNOME shell extensions
          gnome-tweaks # Tool to customize advanced GNOME 3 options
          switcheroo # Gnome app for converting (and resizing) images between different formats (uses imagemagick)
        ])
        ++ (with pkgs.gnomeExtensions; [
          appindicator # Adds AppIndicator, KStatusNotifierItem and legacy Tray icons support to the Shell.
        ]);
      # Use `dconf watch /` to track stateful changes you are doing, then set them here
      dconf.settings = {
        # organise the apps menu into folders
        "org/gnome/desktop/app-folders" = {
          folder-children = [
            "Utilities"
            "System"
            "Calibre"
            "Gnome Tools"
            "LibreOffice"
            "Nix"
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
        "org/gnome/desktop/app-folders/folders/Gnome Tools" = {
          name = "Gnome Tools";
          apps = [
            "com.mattjakeman.ExtensionManager.desktop"
            "org.gnome.tweaks.desktop"
            "ca.desrt.dconf-editor.desktop"
          ];
          translate = false;
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
        "org/gnome/desktop/app-folders/folders/Nix" = {
          name = "Nix";
          apps = [
            "nixos-manual.desktop"
            "home-manager-manual.desktop"
          ];
          translate = false;
        };
        "org/gnome/desktop/interface" = {
          # set the system to dark mode
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
        };
        "org/gnome/shell" = {
          disable-user-extensions = false;
          # `gnome-extensions list` for a list
          enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
          ];
        };
        "org/gnome/desktop/wm/keybindings" = {
          # workaround for problem with the ALT-F2 default for the Gnome run dialog
          panel-run-dialog = [ "<Alt>S" ];
        };
        # "org/gnome/desktop/peripherals/keyboard" = {
        # delay = lib.hm.gvariant.mkUint32 175;
        # disable to check
        # repeat = false;
        # repeat-interval = lib.hm.gvariant.mkUint32 18;
        # };
      };
      gtk = {
        enable = true;
        # enable dark theme on legacy apps
        gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
      };
      qt = {
        enable = true;
        # give Qt apps a similar look and feel to the adwaita-dark theme used by Gnome
        # See https://wiki.nixos.org/wiki/GNOME#GNOME_Qt_integration
        platformTheme.name = "adwaita";
        style.name = "adwaita-dark";
      };
    };
  };
}
