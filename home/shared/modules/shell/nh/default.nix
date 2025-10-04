{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mettavi.shell.nh;
in
{
  options.mettavi.shell.nh = {
    enable = lib.mkEnableOption "Install the nh (nix helper) tool";
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
    };
    home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
      # prevent nh from checking for flakes "experimental features" on darwin (which it can't read from determinate nix.conf)
      NH_NO_CHECKS = "1";
    };
  };
}
