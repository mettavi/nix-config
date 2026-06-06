{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mettavi.services.davmail;
in
{
  options.mettavi.services.davmail = {
    enable = mkEnableOption "Set up a davmail bridge to connect to a MS Exchange server from a 3rd-party client";
  };

  config = mkIf cfg.enable {
    services.davmail = {
      enable = true;
      imitateOutlook = true;
      # See: https://davmail.sourceforge.net/serversetup.html
      settings = {
        "davmail.mode" = "O365Interactive";
      };
    };
  };
}
