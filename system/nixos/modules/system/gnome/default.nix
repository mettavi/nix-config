{
  config,
  lib,
  pkgs,
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
      systemPackages =
        with pkgs;
        with pkgs.gst_all_1;
        [
          celluloid # GTK frontend for the mpv video player
          # GStreamer plugins
          gst-plugins-base
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav # FFmpeg plugin for GStreamer
          gst-vaapi # Set of VAAPI GStreamer Plug-ins
        ];
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
  };
}
