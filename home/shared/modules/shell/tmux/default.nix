{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nyx.modules.shell.tmux;
  df_sh = config.nyx.modules.shell.default;

  # EXAMPLE USE OF mkTmuxPlugin function to install plugins directly from GitHub
  tpm = pkgs.tmuxPlugins.mkTmuxPlugin rec {
    pluginName = "tpm";
    version = "3.1.0";
    rtpFilePath = "tpm";
    src = pkgs.fetchFromGitHub {
      owner = "tmux-plugins";
      repo = "tpm";
      rev = "v${version}";
      hash = "sha256-CeI9Wq6tHqV68woE11lIY4cLoNY8XWyXyMHTDmFKJKI=";
    };
  };
in
{
  options.nyx.modules.shell.tmux = {
    enable = mkEnableOption "Install and configure tmux";
  };

  config = mkIf cfg.enable {
    programs = {
      tmux = {
        enable = true;
        baseIndex = 1;
        # this still requires the vim-tmux-navigator plugin in vim/neovim?
        customPaneNavigationAndResize = true;
        # override default (500) with a better value, see https://github.com/tmux/tmux/issues/3844 for a discussion
        escapeTime = 10;
        extraConfig = # sh
          ''
            # Allow Ctrl+a to be passed to the terminal
            bind a send-prefix
            # Allow programs to bypass tmux using a terminal escape sequence (eg for image rendering)
            set -g allow-passthrough on
            # recommended by yazi to enable proper image rendering
            set -ga update-environment TERM
            set -ga update-environment TERM_PROGRAM
            # Enable true-color/italics in a terminal in tmux
            set -ga terminal-overrides ',xterm*:Tc:sitm=\E[3m'
            set -g status-position top
            # renumber open windows when one is closed
            set -g renumber-windows on
            # use semicolon to enter command mode
            bind \; command-prompt
            unbind %
            bind | split-window -h -c "#{pane_current_path}" # opens in cwd rather than original
            unbind '"'
            bind - split-window -v -c "#{pane_current_path}" # opens in cwd rather than original
            # open a new window in the cwd
            bind c new-window -c "#{pane_current_path}"
            # reload tmux config with <prefix>-r
            unbind r
            bind r source-file ~/.config/tmux/tmux.conf \; display-message "Tmux config reloaded!"
            # maximise a pane (toggle)
            bind -r m resize-pane -Z
            # clear screen with <prefix>-C-l (for "CAPS-LOCK as CTRL" need to release key in between) 
            bind C-l send-keys 'C-l' 
            bind -T copy-mode-vi 'v' send -X begin-selection # select text by character/line, and V for full-line (no space necessary)
            bind -T copy-mode-vi 'C-v' send -X rectangle-toggle \; send -X begin-selection # block-select text (with required space added)
            bind -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"
            unbind -T copy-mode-vi MouseDragEnd1Pane # don't exit copy mode when dragging with mouse
            set -g status-right-length 100
            set -g status-left-length 100
          '';
        # allow nvim to intercept focus events from the terminal emulator (enables autoread to reload changed files)
        focusEvents = true;
        historyLimit = 50000;
        keyMode = "vi";
        mouse = true;
        plugins = with pkgs.tmuxPlugins; [
          {
            plugin = catppuccin;
            extraConfig = ''
              set -g @catppuccin_flavor "mocha"
              set -g @catppuccin_window_status_style "rounded"
              set -g @catppuccin_window_number_position "right"
              set -g @catppuccin_window_default_text "#W"
              set -g @catppuccin_window_text "#W"
              set -g @catppuccin_window_current_text "#W"
              set -g status-right "#{E:@catppuccin_status_directory}"
              set -ag status-right "#{E:@catppuccin_status_host}"
              set -ag status-right "#{E:@catppuccin_status_uptime}"
              set -agF status-right "#{E:@catppuccin_status_cpu}"
              set -agF status-right "#{E:@catppuccin_status_battery}" 
            '';
          }
          cpu
          battery
          {
            plugin = prefix-highlight;
            extraConfig = ''
              set -g status-left "#{prefix_highlight}"
              set -g @prefix_highlight_fg 'black'
              set -g @prefix_highlight_bg 'yellow'
              set -g @prefix_highlight_show_copy_mode 'on'
              set -g @prefix_highlight_show_sync_mode 'on'
              set -g @prefix_highlight_copy_mode_attr 'fg=black,bg=white'
              set -g @prefix_highlight_sync_mode_attr 'fg=black,bg=green'
            '';
          }
          {
            plugin = tpm;
            extraConfig = ''
              set -g @plugin 'tmux-plugins/tpm'
              set-environment -g TMUX_PLUGIN_MANAGER_PATH '${config.xdg.dataHome}/tmux/plugins/tpm'
              set -g @plugin 'alexwforsythe/tmux-which-key'
              set -g @tmux-which-key-xdg-enable=1
            '';
          }
        ];
        shell = "${pkgs.${df_sh}}/bin/${df_sh}";
        shortcut = "a";
        terminal = "tmux-256color";
        tmuxp.enable = true;
      };
      zsh.shellAliases = {
        tm = "tmux";
        tkw = "tmux kill-window";
      };
    };
    xdg.configFile = {
      "tmuxp/nvim-zsh.yaml".source = ../../../dots/tmuxp/nvim-zsh.yaml;
    };
  };
}
