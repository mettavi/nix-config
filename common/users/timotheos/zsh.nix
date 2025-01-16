{
  programs.zsh = {
    enable = true;
    antidote = {
      enable = true;
      plugins = [
        "Aloxaf/fzf-tab"
        "olets/zsh-autosuggestions-abbreviations-strategy"
        "MichaelAquilina/zsh-you-should-use"
      ];
    };
    autosuggestion.enable = true;
    completionInit = (builtins.readFile ../../../modules/zsh/.config/zsh/.zsh_completions);
    dotDir = ".config/zsh";
    envExtra = (builtins.readFile ../../../modules/zsh/.config/zsh/.zshenv);
    history = {
      path = "$ZDOTDIR/.zsh_history";
      save = 100000;
      size = 100000;
    };
    initExtraFirst = (builtins.readFile ../../../modules/zsh/.config/zsh/.zshrc_top);
    initExtra = (builtins.readFile ../../../modules/zsh/.config/zsh/.zshrc);
    sessionVariables = {
      # alias for thefuck command
      TF_ALIAS = "oh";
    };
    syntaxHighlighting.enable = true;
    zsh-abbr.enable = true;
  };
}
