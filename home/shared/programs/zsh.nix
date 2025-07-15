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
    completionInit = (builtins.readFile ../../../dots/zsh/.zsh_completions);
    dotDir = ".config/zsh";
    enableCompletion = true;
    envExtra = (builtins.readFile ../../../dots/zsh/.zshenv);
    history = {
      path = "$ZDOTDIR/.zsh_history";
      save = 100000;
      size = 100000;
    };
    initContent = lib.mkMerge [
      (lib.mkBefore (builtins.readFile ../../../dots/zsh/.zshrc_top))
      (builtins.readFile ../../../dots/zsh/.zshrc)
    ];
    # Assign the alias to different binaries depending on host OS
    shellAliases = {
      ts = if pkgs.stdenv.isDarwin then "trash" else "trash-put";
      rm = "echo 'Please use ts instead.'; false";
    };
    shellGlobalAliases = {
      # use gnu ls on darwin for nicer default colors
      ls = if pkgs.stdenv.isDarwin then "gls --color" else "ls --color";
    };
    syntaxHighlighting.enable = true;
    zsh-abbr.enable = true;
  };
}
