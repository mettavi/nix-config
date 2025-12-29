{
  config,
  lib,
  pkgs,
  ...
}:
let
  office = pkgs.libreoffice-fresh-unwrapped;
  cfg = config.mettavi.system.apps.libreoffice;
in
{
  options.mettavi.system.apps.libreoffice = {
    enable = lib.mkEnableOption "Install and set up libreoffice suite";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libreoffice-fresh
      hunspell
      hunspellDicts.en_AU
      hunspellDicts.en_US
      hyphenDicts.en_US
    ];
    environment.sessionVariables = {
      PYTHONPATH = "${office}/lib/libreoffice/program";
      URE_BOOTSTRAP = "vnd.sun.star.pathname:${office}/lib/libreoffice/program/fundamentalrc";
    };
  };
}
