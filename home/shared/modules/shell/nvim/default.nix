{
  config,
  lib,
  nix_repo,
  pkgs,
  ...
}:

with lib;
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.nyx.shell.nvim;
in
{
  options.nyx.shell.nvim = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure neovim";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      neovim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          noice-nvim
          telescope-fzf-native-nvim
        ];
      };
      zsh.shellGlobalAliases = {
        nv = "nvim";
        nvc = "cd ~/.config/nvim";
        nvs = "cd ~/.local/share/nvim";
      };
    };
    xdg.configFile = {
      # link without copying to nix store (manage externally) - must use absolute paths
      # mkOutOfStoreSymlink is required to allow the lazy-lock.json file to be writable
      "nvim".source =
        mkOutOfStoreSymlink "${config.home.homeDirectory}/${nix_repo}/home/shared/dots/nvim";
    };
  };
}
