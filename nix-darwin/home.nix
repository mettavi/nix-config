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
    aria2.enable = true;
    atuin.enable = true;
    bat.enable = true;
    fd.enable = true;
    fzf.enable = true;
    git.enable = true;
    git.delta.enable = true;
    jq.enable = true;
    keychain.enable = true;
    lazygit.enable = true;
    neovim.enable = true;
    pyenv.enable = true;
    qt.enable = true;
    rbenv.enable = true;
    zsh.antidote.enable = true;
    # programs.zsh.promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    # tmux = import ../home/tmux.nix { inherit pkgs; };
    # zsh = import ../home/zsh.nix { inherit config pkgs; };
    # #zoxide = (import ../home/zoxide.nix { inherit config pkgs; });
    # fzf = import ../home/fzf.nix { inherit pkgs; };
  };
}
