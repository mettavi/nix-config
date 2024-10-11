{ config, pkgs, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  programs.home-manager.enable = true;
  manual.html.enable = true;
  home.username = "timotheos";
  home.homeDirectory = "/Users/timotheos";
  xdg.enable = true;

  # xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/timotheos/.dotfiles/.config/nvim";

  home.stateVersion = "23.11";

  programs = {
    # tmux = import ../home/tmux.nix { inherit pkgs; };
    # zsh = import ../home/zsh.nix { inherit config pkgs; };
    # #zoxide = (import ../home/zoxide.nix { inherit config pkgs; });
    # fzf = import ../home/fzf.nix { inherit pkgs; };
  };
}
