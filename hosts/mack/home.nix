{
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  # install the HTML manual and "home-manager-help" command
  manual.html.enable = true;

  home = {
    username = "timotheos";
    homeDirectory = "/Users/timotheos";
    stateVersion = "23.11";
    # make programs use XDG directories whenever supported
    preferXdgDirectories = true;
  };

  imports = [
    # sops config  for home
    ../../modules/sops/sops-home.nix
    # packages
    ../../common/users/timotheos
  ];

  ######## INSTALL SERVICES #########

  services = {
    gpg-agent = {
      enable = true;
      extraConfig = ''
        pinentry-program /usr/local/bin/pinentry-touchid
      '';
    };
  };

  ######## INSTALL PACKAGES #########

  home.packages = with pkgs; [
    atuin
  ];

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
      "zsh/.zsh_aliases".source = ../../modules/zsh/.config/zsh/.zsh_aliases;
    };
  };
  # link without copying to nix store (manage externally) - must use absolute paths
  # xdg.configFile.nvim.source = mkOutOfStoreSymlink "${config.users.users.ta.home}.dotfiles/.config/nvim";

}
