{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mettavi.desktop.gnome;
in
{
  options.mettavi.desktop.gnome = {
    enable = lib.mkEnableOption "Configure Gnome Desktop";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      # GSettings editor for GNOME.
      (with pkgs; [ dconf-editor ])
      ++ (with pkgs.gnomeExtensions; [
        appindicator # Adds AppIndicator, KStatusNotifierItem and legacy Tray icons support to the Shell.
        solaar-extension # Allow Solaar to support certain features on non X11 systems (eg. rules)
      ]);
    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        # `gnome-extensions list` for a list
        enabled-extensions = [
          "solaar-extension@sidevesh"
          "appindicatorsupport@rgcjonas.gmail.com"
        ];
      };
      "org/gnome/desktop/peripherals/keyboard" = {
        # delay = lib.hm.gvariant.mkUint32 175;
        # disable to check
        # repeat = false;
        # repeat-interval = lib.hm.gvariant.mkUint32 18;
      };
    };
  };
}
