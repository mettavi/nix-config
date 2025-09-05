{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.nyx.profiles.mbp;
in
{
  options.nyx.profiles.mbp = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "A profile for my macbookpro, currently my daily OS";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      localsend # Open source cross-platform alternative to AirDrop
      obsidian
      zoom-us # video conferencing applications
      # Install global npm packages not available in nixpkgs repo
      # using node2nix and overlay (see above)
      # npmGlobals.functional-javascript-workshop
      # npmGlobals.how-to-markdown
      # npmGlobals.javascripting
      # npmGlobals.js-best-practices
      npmGlobals.learnyoubash
      # npmGlobals.regex-adventure
      # npmGlobals.zeal-user-contrib
    ];
    home-manager.users.${username} = {
      nyx.modules.shell.restic.enable = true;
      programs = {
        helix = {
          enable = true;
        };
      };
    };
  };
}
