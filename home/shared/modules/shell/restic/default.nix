{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nyx.modules.shell.restic;
in
{
  options.nyx.modules.shell.restic = {
    enable = mkEnableOption "Install and configure the restic backup tool";
    useRProf = mkOption {
      type = types.bool;
      default = true;
      description = "Use resticprofile to manage restic using config files";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      restic # Backup with delta transfers (eg. to cloud storage via rclone)
      (optionalString (cfg.useRProf) resticprofile) # Configuration manager for restic
    ];
    xdg.configFile = mkIf cfg.useRProf {
      "resticprofile".source = ../../../dots/resticprofile;
    };
  };
}
