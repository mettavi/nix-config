{
  config,
  lib,
  nixosConfig,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.shell.fzf;
  currentVersion = builtins.fromJSON nixosConfig.system.nixos.release;
in
{
  options.mettavi.shell.fzf = {
    enable = mkEnableOption "Install and configure the fzf command-line fuzzy finder";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      catppuccin = mkIf config.catppuccin.enable {
        fzf = {
          enable = true;
          flavor = "macchiato";
          # NB: A accent for fzf is not supported
          # accent = "sapphire";
        };
      };

      home.packages = with pkgs; [
        # Bash and zsh key bindings for Git objects, powered by fzf
        # see below for zsh source
        fzf-git-sh
      ];

      programs.fzf = {
        enable = true;
        enableBashIntegration = false;
        enableFishIntegration = false;
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
        # changeDirWidget = {
        #   command = "fd --type directory --hidden --follow --strip-cwd-prefix --exclude .git";
        #   options = [ "--preview 'eza --tree --color=always {} | head -200'" ];
        # };
        # configure the CTRL-T keybinding
        # fileWidget = {
        #   command = config.programs.fzf.defaultCommand;
        #   options = [
        #     "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
        #   ];
        # };
        # configure the CTRL-R keybinding
        # historyWidget = {
        #   command = if config.mettavi.shell.atuin.enable then "" else null;
        # };
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
        # source the fzf-git shell script
        initContent = (builtins.readFile "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh");
      };
    })
    # TODO: Remove when version 26.05 is deprecated
    (mkIf cfg.enable {
      programs.fzf =
        let
          fzfDirCommand = "fd --type directory --hidden --follow --strip-cwd-prefix --exclude .git";
          fzfDirOptions = [ "--preview 'eza --tree --color=always {} | head -200'" ];
          fzfFileOptions = [
            "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
          ];
          useAtuinHistory = if config.mettavi.shell.atuin.enable then "" else null;
        in
        if currentVersion < 26.11 then
          {
            # configure the ALT-C keybinding
            changeDirWidgetCommand = fzfDirCommand;
            changeDirWidgetOptions = fzfDirOptions;
            # configure the CTRL-T keybinding
            fileWidgetCommand = config.programs.fzf.defaultCommand;
            fileWidgetOptions = fzfFileOptions;
            # configure the CTRL-R keybinding
            historyWidgetCommand = useAtuinHistory;
          }
        else
          {
            enableNushellIntegration = false;
            # configure the ALT-C keybinding
            changeDirWidget.command = fzfDirCommand;
            changeDirWidget.options = fzfDirOptions;
            # configure the CTRL-T keybinding
            fileWidget.command = config.programs.fzf.defaultCommand;
            fileWidget.options = fzfFileOptions;
            # configure the CTRL-R keybinding
            historyWidget.command = useAtuinHistory;
          };
    })
  ];
}
