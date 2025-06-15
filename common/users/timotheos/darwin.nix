{ config, user1, ... }:
{
  # SYSTEM PREFERENCES FOR USER1 ON HOST "MACK" (DARWIN)

  # NIX-DARWIN OPTIONS
  system.defaults.dock = {
    persistent-apps = [
      "/System/Applications/System Settings.app"
      "/System/Applications/Calendar.app"
      "/System/Applications/App Store.app"
      "/Applications/Google Chrome.app"
      "/Applications/iTerm.app"
      "/Applications/Microsoft Word.app"
      "/Users/${user1}/.dotfiles/common/users/${user1}/bin/CaliSync.app"
    ];
  };

  home.sessionVariables = {
    # prevent nh from checking for flakes "experimental features" (which it can't read from determinate nix.conf)
    NH_NO_CHECKS = "1";
  };

  # HOME_MANAGER OPTIONS
  home-manager.users.${user1} = {
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
            "${config.users.users.${user1}.home}/.dotfiles/common/users/${user1}/bin/bw_backup.sh"
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
}
