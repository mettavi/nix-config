{ pkgs, ... }:
let
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
    hash = "sha256-Zi+54ZwoXDKKeUHSTYkif8m0FKx6V8nA6mByaVyBrks=";
  };
in
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    flavors = {
      catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";
    };
    keymap = {
      manager.prepend_keymap = [
        {
          on = [ "<S-a>" ];
          run = "toggle_all --state=on";
          desc = "Select all files";
        }
      ];
    };
    settings = {
      manager = {
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
}
