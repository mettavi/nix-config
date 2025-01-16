{ pkgs, ... }:
{
  programs = {
    bash = {
      # this will enable and install bash-completion package (bash.enableCompletion is deprecated)
      completion.enable = true;
    };
    #   fish.enable = true;
    # Create /etc/zshrc that loads the nix-darwin environment.
    zsh = {
      enable = true;
      promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}
