{
  config,
  hostname,
  lib,
  nix_repo,
  username,
  ...
}:
{
  imports = [ ./mac ];

  system.defaults = {
    dock = {
      autohide = true;
      persistent-apps = [
        "/System/Applications/System Settings.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/App Store.app"
        "/Applications/Google Chrome.app"
        "/Applications/iTerm.app"
        "/Applications/Microsoft Word.app"
        "/Users/${username}/${nix_repo}/home/darwin/_files/calibre/CaliSync.app"
      ];
    };
    # check current setting with "defaults read NSGlobalDomain '<insert setting here>'"
    NSGlobalDomain = {
      AppleKeyboardUIMode = 2;
      ApplePressAndHoldEnabled = false;
      # GUI steps (L to R): InitialKeyRepeat: 120, 94, 68, 35, 25, 15 / KeyRepeat: 120, 90, 60, 30, 12, 6, 2
      # (See https://apple.stackexchange.com/questions/261163/default-value-for-nsglobaldomain-initialkeyrepeat)
      InitialKeyRepeat = 35; # default 25
      KeyRepeat = 6; # default 6
    };
    trackpad = {
      TrackpadThreeFingerDrag = true;
    };
  };

  environment.etc = {
    "newsyslog.d/restic.conf".text =
      lib.mkIf config.home-manager.users.${username}.mettavi.shell.restic.enable # bash
        ''
          # logfilename                      [owner:group]      mode count size(KB)  when  flags [/pid_file]     [sig_num] 
          ${
            config.users.users.${username}.home
          }/Library/Logs/restic/${hostname}-${username}-b2bak.log    root:staff         644  30    1024      *     NJ 
          ${
            config.users.users.${username}.home
          }/Library/Logs/restic/${hostname}-${username}-b2rcl.log    root:staff         644  30    1024      *     NJ 
          ${
            config.users.users.${username}.home
          }/Library/Logs/restic/${hostname}-${username}-b2prn.log    root:staff         644  4     1024      *     NJ 
          ${
            config.users.users.${username}.home
          }/Library/Logs/restic/${hostname}-${username}-b2chk.log    root:staff         644  1     1024      *     NJ 
        '';
  };
}
