{
  config,
  lib,
  nix_repo,
  pkgs,
  ...
}:
with lib;
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.nyx.modules.shell.zsh;
in
{
  options.nyx.modules.shell.zsh = {
    setup = mkOption {
      type = types.bool;
      default = true;
      description = "Fully configure zsh for the user";
    };
    prompt = mkOption {
      type = types.enum [
        "manual"
        "p10k"
      ];
      default = "p10k";
      description = "Set the shell prompt";
    };
  };

  config = mkIf cfg.setup {
    home.file = mkIf (cfg.prompt == "p10k") {
      # powerlevel10k prompt preferences (needs to be writeable, hence the use of mkOutOfStoreSymlink)
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
      autocd = true;
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
      initContent = mkMerge [
        # load code to enable instant prompt in powerlevel10k
        (optionalString (cfg.prompt == "p10k") (
          lib.mkBefore (builtins.readFile ../../../dots/zsh/.zshrc_top)
        ))
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
