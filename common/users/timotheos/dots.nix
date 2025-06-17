{ config, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  ####### CONFIGURE PACKAGES USING DOTFILES ########

  # link config file or whole directory to ~
  # home.file."foo".source = ./bar;

  # link the contents of a directory to ~
  # home.file."bin" = {
  #   source = ./bin;
  #   recursive = true;
  #   executable = true;
  # };

  # link config file/directory to ~/.config (use "recursive" for dir contents)
  # xdg = {
  #   enable = true;
  #   configFile."foo" = {
  #     source = ./bar;
  #   };
  # };

  home.file = {
    ".gitconfig".source = ../../../modules/git/.gitconfig;
    ".gitignore_global".source = ../../../modules/git/.gitignore_global;
  };

  xdg = {
    # enable management of xdg base directories
    enable = true;
    configFile = {
      "atuin".source = ../../../modules/atuin;
      "fzf/.fzfrc".source = ../../../modules/fzf/.fzfrc;
      # link the whole nvim directory
      "nvim".source = ../../../modules/nvim;
      # "rclone/filter-calibre.txt".source = ./conf/rclone/filter-calibre.txt;
      "zsh/.zsh_aliases".source = ../../../modules/zsh/.zsh_aliases;
      "zsh/.zsh_functions".source = ../../../modules/zsh/.zsh_functions;
    };
  };
  # link without copying to nix store (manage externally) - must use absolute paths
  # xdg.configFile.nvim.source = mkOutOfStoreSymlink "${self}/.config/nvim";
}
