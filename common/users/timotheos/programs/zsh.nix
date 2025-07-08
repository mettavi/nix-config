{ lib, pkgs, ... }:
{
  # NB: Completions are enabled by default
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
    completionInit = (builtins.readFile ../../../../modules/zsh/.zsh_completions);
    dotDir = ".config/zsh";
    enableCompletion = true;
    envExtra = (builtins.readFile ../../../../modules/zsh/.zshenv);
    history = {
      path = "$ZDOTDIR/.zsh_history";
      save = 100000;
      size = 100000;
    };
    initContent = lib.mkMerge [
      (lib.mkBefore (builtins.readFile ../../../../modules/zsh/.zshrc_top))
      (builtins.readFile ../../../../modules/zsh/.zshrc)
    ];
    # Assign the alias to different binaries depending on host OS
    shellAliases = {
      ts = if pkgs.stdenv.isDarwin then "trash" else "trash-put";
      rm = "echo 'Please use ts instead.'; false";
    };
    syntaxHighlighting.enable = true;
    zsh-abbr.enable = true;
  };
}
