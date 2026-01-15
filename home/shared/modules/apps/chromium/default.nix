{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.apps.chromium;
in
{
  options.mettavi.apps.chromium = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure chromium or one of its relatives";
    };
  };
  config = mkIf cfg.enable {
    programs.brave = {
      enable = true;
      dictionaries = [
        pkgs.hunspellDictsChromium.en_US
      ];
      # NB: In order to install extensions in brave, use programs.brave rather than programs.chromium
      extensions = [
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # dark reader
        { id = "hipekcciheckooncpjeljhnekcoolahp"; } # tabliss
        { id = "iaiomicjabeggjcfkbimgmglanimpnae"; } # tab session messenger
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      ];
      commandLineArgs = [
        "--disable-features=AutofillSavePaymentMethods"
      ];
      package = pkgs.brave;
    };
  };
}
