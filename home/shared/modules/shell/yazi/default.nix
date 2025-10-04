{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mettavi.shell.yazi;

  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "main";
    hash = "";
  };

  yazi-flavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "main";
    hash = "sha256-60XGlsdIoEJw7nf/3d6nOKsC/r83MRN5jeal2I3BYQM=";
  };
in
{
  options.mettavi.shell.yazi = {
    enable = lib.mkEnableOption "Install and configure yazi";
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      flavors = {
        catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [ "<S-a>" ];
            run = "toggle_all --state=on";
            desc = "Select all files";
          }
        ];
      };
      settings = {
        mgr = {
          # increase width of parent from default
          ratio = [
            2
            3
            4
          ];
          show_hidden = true;
        };
        preview = {
          max_width = 1200;
          max_height = 1000;
        };
      };
      theme = {
        flavor = {
          dark = "catppuccin-mocha";
          light = "catppuccin-mocha";
        };
      };
      shellWrapperName = "y";
    };
  };
}
