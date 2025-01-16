{
  system.defaults = {
    dock.autohide = true;
    # check current setting with "defaults read NSGlobalDomain '<insert setting here>'"
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      # GUI steps (L to R): InitialKeyRepeat: 120, 94, 68, 35, 25, 15 / KeyRepeat: 120, 90, 60, 30, 12, 6, 2
      # (See https://apple.stackexchange.com/questions/261163/default-value-for-nsglobaldomain-initialkeyrepeat)
      InitialKeyRepeat = 35; # default 25 
      KeyRepeat = 6; # default 6
    };
  };
}
