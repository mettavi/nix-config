{ config, nix_repo, ... }:
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
    ".npmrc".source = ../../../modules/node/.npmrc;
    # "Library/Preferences/com.plexapp.plexmediaserver.plist".source =
    #  if pkgs.stdenv.isDarwin then ../../../modules/plex/com.plexapp.plexmediaserver.plist else "";
    # powerlevel10k prompt preferences
    ".p10k.zsh".source =
      mkOutOfStoreSymlink "${config.home.homeDirectory}/${nix_repo}/modules/zsh/.p10k.zsh";
  };

  xdg = {
    # enable management of xdg base directories
    enable = true;
    configFile = {
      "atuin".source = ../../../modules/atuin;
      "bat/themes/tokyonight_night.tmTheme".source = ../../../modules/bat/themes/tokyonight_night.tmTheme;
      "fzf/.fzfrc".source = ../../../modules/fzf/.fzfrc;
      # link without copying to nix store (manage externally) - must use absolute paths
      # mkOutOfStoreSymlink is required to allow the lazy-lock.json file to be writable
      "nvim".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/${nix_repo}/modules/nvim";
      "resticprofile".source = ../../../modules/resticprofile;
      "tmuxp/nvim-zsh.yaml".source = ../../../modules/tmuxp/nvim-zsh.yaml;
      "zsh/.zsh_aliases".source = ../../../modules/zsh/.zsh_aliases;
      "zsh/.zsh_functions".source = ../../../modules/zsh/.zsh_functions;
    };
  };
}
