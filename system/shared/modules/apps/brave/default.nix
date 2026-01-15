{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.apps.brave;
in
{
  options.mettavi.apps.brave = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure chromium or one of its relatives";
    };
  };
  config = mkIf cfg.enable {
    # see https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy for a list of brave policy settings
    # environment.etc."/brave/policies/managed/GroupPolicy.json".source = ./policies.json;
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
