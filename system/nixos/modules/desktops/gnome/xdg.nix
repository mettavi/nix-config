{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.desktops.gnome;
in
{
  config = mkIf cfg.enable {
    # set gtk as the default interface
    xdg.portal = {
      enable = true;
      config = lib.mkForce {
        common = {
          default = [
            "gtk"
          ];
        };
        gnome = {
          default = [
            "gnome"
            "gtk"
          ];
          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };
      };
      extraPortals =
        with pkgs;
        # required for screensharing functionality on Wayland
        [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk # Use this for GNOME (may already be default)
          # xdg-desktop-portal-wlr # Use this for Sway/wlroots
          # xdg-desktop-portal-kde  # Use this for KDE
        ];
    };
  };
}
