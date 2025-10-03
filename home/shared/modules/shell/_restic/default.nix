{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nyx.shell.restic;
in
{
  options.nyx.shell.restic = {
    enable = mkEnableOption "Install and configure the restic backup tool";
    useRProf = mkOption {
      type = types.bool;
      default = true;
      description = "Use resticprofile to manage restic using config files";
    };
  };

  config =
    mkIf cfg.enable {
      home.packages = with pkgs; [
        restic # Backup with delta transfers (eg. to cloud storage via rclone)
      ];
    }
    // mkIf cfg.useRProf {
      home.packages = with pkgs; [ resticprofile ]; # Configuration manager for restic
      xdg.configFile = {
        "resticprofile".source = ../../../dots/resticprofile;
      };
    };
}
