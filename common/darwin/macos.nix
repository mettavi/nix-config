{ pkgs, self, user1, ... }:
{
  imports = [ ./mac ];

  system.defaults = {
    dock.autohide = true;
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
       # automatically detects files in the store that have identical contents, and replaces them with hard links to a single copy
       auto-optimise-store = true
       warn-dirty = false
       lazy-trees = true
       trusted-users = root
       extra-substituters = https://nixpkgs.cachix.org https://nix-community.cachix.org https://cachix.cachix.org https://yazi.cachix.org https://mettavi.cachix.org  
       extra-trusted-public-keys = nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM= yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k= mettavi.cachix.org-1:rYvLGZOMT4z4hK7u5pzrbt8svJ/2JcUA/PTa1bQx4FU=
       extra-nix-path =  nixpkgs-overlays=${self}/common/overlays
      '';
    # pam_reattach.so re-enables pam_tid.so in tmux
    "pam.d/sudo_local".text = # bash
      ''
        # Managed by Nix Darwin
        auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
        auth       sufficient     pam_tid.so
      '';
  };
}
