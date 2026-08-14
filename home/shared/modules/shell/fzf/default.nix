{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.shell.fzf;
in
{
  options.mettavi.shell.fzf = {
    enable = mkEnableOption "Install and configure the fzf command-line fuzzy finder";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Bash and zsh key bindings for Git objects, powered by fzf
      # see below for zsh source
      fzf-git-sh
    ];

    programs.fzf = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableNushellIntegration = false;
      enableZshIntegration = config.mettavi.shell.zsh.setup;

      defaultCommand = "fd --hidden --follow --strip-cwd-prefix --exclude .git";
      defaultOptions = [
        "-m"
        "--height 50%"
        "--tmux bottom,40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
        ''
          --bind ctrl-y:preview-up,ctrl-e:preview-down,\
          ctrl-b:preview-page-up,ctrl-f:preview-page-down,\
          ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,\
          shift-up:preview-top,shift-down:preview-bottom,\
          alt-up:half-page-up,alt-down:half-page-down
        ''
      ];
      # configure the ALT-C keybinding
      changeDirWidget = {
        command = "fd --type directory --hidden --follow --strip-cwd-prefix --exclude .git";
        options = [ "--preview 'eza --tree --color=always {} | head -200'" ];
      };
      # configure the CTRL-T keybinding
      fileWidget = {
        command = config.programs.fzf.defaultCommand;
        options = [
          "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
        ];
      };
      # configure the CTRL-R keybinding
      historyWidget = {
        command = if config.mettavi.shell.atuin.enable then "" else null;
      };
      tmux = mkIf config.mettavi.shell.tmux.enable {
        # Sets FZF_TMUX=1, enabling fzf in tmux popups
        enableShellIntegration = true;
        # open in popup windows in 80% width, 60% height
        shellIntegrationOptions = [ "-p 80%,60%" ];
      };
    };

    programs.zsh = {
      enable = true;
      antidote = {
        enable = true;
        plugins = [
          "Aloxaf/fzf-tab"
        ];
      };
      completionInit = # sh
        ''
          # Configure fzf ** completion
          # - The first argument to the function ($1) is the base path to start traversal
          # - See the source code (completion.{bash,zsh}) for the details.
          _fzf_compgen_path() {
            fd --hidden --follow --exclude .git . "$1"
          }

          # Use fd to generate the list for directory completion
          _fzf_compgen_dir() {
            fd --type=d --hidden --follow --exclude .git . "$1"
          }

          # Advanced customization of fzf options via _fzf_comprun function
          # - The first argument to the function is the name of the command.
          # - You should make sure to pass the rest of the arguments to fzf.
          _fzf_comprun() {
            local command=$1
            shift

            case "$command" in
              cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
              export|unset) fzf --preview "eval 'echo ''${}'"         "$@" ;;
              ssh)          fzf --preview 'dig {}'                   "$@" ;;
              *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
            esac
          }
        '';
      # source the fzf-git shell script
      initContent = (builtins.readFile "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh");
    };
  };
}
