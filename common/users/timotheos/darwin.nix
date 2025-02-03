{ user1, ... }:
{
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
}
