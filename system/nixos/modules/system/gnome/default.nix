{
  config,
  lib,
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
