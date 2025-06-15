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

  xdg = {
    # enable management of xdg base directories
    enable = true;
    configFile = {
      # "rclone/filter-calibre.txt".source = ./conf/rclone/filter-calibre.txt;
      "zsh/.zsh_aliases".source = ../../../modules/zsh/.config/zsh/.zsh_aliases;
    };
  };
  # link without copying to nix store (manage externally) - must use absolute paths
  # xdg.configFile.nvim.source = mkOutOfStoreSymlink "${config.users.users.ta.home}.${repo_home}/.config/nvim";
}
