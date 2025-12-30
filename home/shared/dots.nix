let
  # link without copying to nix store (manage externally) - must use absolute paths
  # inherit (config.lib.file) mkOutOfStoreSymlink;
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
    ".gitconfig".source = ./dots/git/.gitconfig;
    ".gitignore_global".source = ./dots/git/.gitignore_global;
    ".npmrc".source = ./dots/node/.npmrc;
    # "Library/Preferences/com.plexapp.plexmediaserver.plist".source =
    #  if pkgs.stdenv.isDarwin then ./dots/plex/com.plexapp.plexmediaserver.plist else "";
  };

  xdg = {
    # enable management of xdg base directories
    enable = true;
    configFile = {
      "atuin".source = ./dots/atuin;
      "bat/themes/tokyonight_night.tmTheme".source = ./dots/bat/themes/tokyonight_night.tmTheme;
      "fastfetch/config.jsonc".source = ./dots/fastfetch/config.jsonc;
      "fzf/.fzfrc".source = ./dots/fzf/.fzfrc;
      "mpv/mpv.conf".text = ''
        # enable hardware acceleration
        hwdec=auto
      '';
    };
  };
}
