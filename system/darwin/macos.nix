{
  config,
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
    "nix/nix.custom.conf".text = # bash
      ''
        # import this file into nix.conf (set "access-tokens" key to my GitHub token to get a higher API threshold for rate-limiting)
        # see https://github.com/NixOS/nix/issues/6536 for more details
        !include ${config.home-manager.users.${username}.sops.secrets."users/${username}/github_token".path}
        # automatically detects files in the store that have identical contents, and replaces them with hard links to a single copy
        auto-optimise-store = true
        warn-dirty = false
        lazy-trees = true
        trusted-users = [ "@staff" "root" ]
        extra-substituters = https://nixpkgs.cachix.org https://nix-community.cachix.org https://cachix.cachix.org https://yazi.cachix.org https://mettavi.cachix.org  
        extra-trusted-public-keys = nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM= yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k= mettavi.cachix.org-1:rYvLGZOMT4z4hK7u5pzrbt8svJ/2JcUA/PTa1bQx4FU=
        extra-nix-path =  nixpkgs-overlays=${
          config.users.users.${username}.home
        }/${nix_repo}/system/overlays
      '';
    "newsyslog.d/restic.conf".text =
      lib.mkIf config.home-manager.users.${username}.nyx.modules.shell.restic.enable # bash
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
