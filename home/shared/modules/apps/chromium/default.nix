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
    programs.chromium = {
      enable = true;
      package = pkgs.brave;
    };
  };
}
