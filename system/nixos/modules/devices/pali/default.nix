{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.gvariant;
let
  cfg = config.mettavi.system.devices.pali;
in
{
  options.mettavi.system.devices.pali = {
    enable = mkEnableOption "Set up the system to read and write with Pali/Sanskrit/Devanagiri characters";
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      # good fonts for romanized Pali
      # See https://discourse.suttacentral.net/t/favorite-pali-fonts-for-romanized-text/18013
      eb-garamond
      gentium
      source-code-pro
      source-sans
      source-serif
    ];

    # install a custom keyboard layout for Pali
    # See https://discourse.suttacentral.net/t/insert-pali-and-sanskrit-characters-with-diacritical-marks-on-discourse-and-operating-systems/311/50
    services.xserver.xkb.extraLayouts = {
      pps = {
        description = "English, with Pali, Prakrit and Sanskrit";
        languages = [ "eng" ];
        symbolsFile = ./pps.xkb;
      };
    };

    home-manager.users.${username} = mkIf config.mettavi.system.desktops.gnome.enable {
      dconf.settings = {
        "org/gnome/desktop/input-sources" = {
          # enable the custom pps keyboard layout above as an input source in gnome
          sources = [
            (mkTuple [
              "xkb"
              "pps"
            ])
          ];
        };
      };
    };
  };
}
