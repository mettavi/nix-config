{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.nyx.modules.shell.nvim;
in
{
  options.nyx.modules.shell.nvim = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and configure neovim";
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        noice-nvim
        telescope-fzf-native-nvim
      ];
    };
  };
}
