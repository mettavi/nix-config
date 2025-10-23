{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mettavi.apps.libreoffice;
in
{
  options.mettavi.apps.libreoffice = {
    enable = lib.mkEnableOption "Install and set up libreoffice suite";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      libreoffice
      hunspell
      hunspellDicts.en_AU
      hunspellDicts.en_US
    ];
    home.sessionVariables = {
      PYTHONPATH = "${pkgs.libreoffice}/lib/libreoffice/program";
      URE_BOOTSTRAP = "vnd.sun.star.pathname:${pkgs.libreoffice}/lib/libreoffice/program/fundamentalrc";
    };
  };
}
