{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.profiles.mbp;
in
{
  options.mettavi.profiles.mbp = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "A profile for my daily driver (currently a macbookpro)";
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
    mettavi.system = {
      shell = {
        kanata.enable = true;
      };
    };
    home-manager.users.${username} = {
      mettavi.shell.restic.enable = true;
    };
  };
}
