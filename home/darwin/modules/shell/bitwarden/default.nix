{
  config,
  lib,
  nix_repo,
  ...
}:
let
  cfg = config.nyx.modules.shell.bw_backup;
in
{
  options.nyx.modules.shell.bw_backup = {
    enable = lib.mkEnableOption "Bitwarden Launchd Backup Task";
  };

  config = lib.mkIf cfg.enable {
    launchd.agents = {
      # make an encrypted backup weekly
      "org.bitwarden.backup" = {
        enable = true;
        config = {
          Label = "org.bitwarden.backup";
          ProgramArguments = [
            "/usr/bin/env"
            "zsh"
            "-c"
            "${config.home.homeDirectory}/${nix_repo}/home/shared/bin/bw_backup.sh"
          ];
          # Run at midnight each Monday (will catch up if system is sleeping)
          StartCalendarInterval = [
            {
              Hour = 0;
              Minute = 0;
              Weekday = 1;
            }
          ];
          StandardErrorPath = /tmp/org.bitwarden.backup.err;
          StandardOutPath = /tmp/org.bitwarden.backup.out;
        };
      };
    };
  };

  # home.sessionVariables = {
  #   # prevent nh from checking for flakes "experimental features" (which it can't read from determinate nix.conf)
  #   NH_NO_CHECKS = "1";
  # };
}
