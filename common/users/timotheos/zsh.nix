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
    completionInit = (builtins.readFile ../../../modules/zsh/.zsh_completions);
    dotDir = ".config/zsh";
    enableCompletion = true;
    envExtra = (builtins.readFile ../../../modules/zsh/.zshenv);
    history = {
      path = "$ZDOTDIR/.zsh_history";
      save = 100000;
      size = 100000;
    };
    initContent =
      lib.mkMerge [
        (lib.mkBefore (builtins.readFile ../../../modules/zsh/.zshrc_top))
        (lib.mkAfter builtins.readFile ../../../modules/zsh/.zshrc)
      ]
      # only add this for ghostty on nixOS (this should come immediately after .zshrc_top)
      ++ lib.optionals (!pkgs.stdenv.isDarwin) [
        ''
          if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
            source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
          fi  
        ''
      ];
    # Only use the aliases on darwin (trash is a mac only package)
    shellAliases = lib.mkIf (pkgs.stdenv.isDarwin) {
      ts = "trash";
      rm = "echo 'Use trash instead'";
    };
    syntaxHighlighting.enable = true;
    zsh-abbr.enable = true;
  };
}
