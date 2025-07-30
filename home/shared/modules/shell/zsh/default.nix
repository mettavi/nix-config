{
  config,
  lib,
  nix_repo,
  pkgs,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.nyx.modules.shell.zsh;
in
{
  options.nyx.modules.shell.zsh = {
    enable = lib.mkEnableOption "Install and configure zsh";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      # powerlevel10k prompt preferences
      ".p10k.zsh".source =
        mkOutOfStoreSymlink "${config.home.homeDirectory}/${nix_repo}/home/shared/dots/zsh/.p10k.zsh";
    };
    xdg.configFile = {
      "zsh/.zsh_aliases".source = ../../../dots/zsh/.zsh_aliases;
      "zsh/.zsh_functions".source = ../../../dots/zsh/.zsh_functions;
    };
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
  };
}
