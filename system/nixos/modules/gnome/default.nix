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
      #   # appindicator
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
    home-manager.users.${username} = {
      home.packages =
        # GSettings editor for GNOME.
        (with pkgs; [
          dconf-editor # GSettings editor for GNOME
          gnome-extension-manager # Desktop app for managing GNOME shell extensions
          gnome-tweaks # Tool to customize advanced GNOME 3 options
          switcheroo # Gnome app for converting (and resizing) images between different formats (uses imagemagick)
        ])
        ++ (with pkgs.gnomeExtensions; [
          appindicator # Adds AppIndicator, KStatusNotifierItem and legacy Tray icons support to the Shell.
        ]);
      dconf.settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false;
          # `gnome-extensions list` for a list
          enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
          ];
        };
        # "org/gnome/desktop/peripherals/keyboard" = {
        # delay = lib.hm.gvariant.mkUint32 175;
        # disable to check
        # repeat = false;
        # repeat-interval = lib.hm.gvariant.mkUint32 18;
        # };
      };
    };
  };
}
