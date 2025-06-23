{
  pkgs,
  ...
}:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    customPaneNavigationAndResize = true;
    # escapeTime = 10;
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
        set -g status-left ""
      '';
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          set -g status-right "#{E:@catppuccin_status_application}"
          set -agF status-right "#{E:@catppuccin_status_cpu}"
          set -ag status-right "#{E:@catppuccin_status_session}"
          set -ag status-right "#{E:@catppuccin_status_uptime}"
          set -agF status-right "#{E:@catppuccin_status_battery}" 
        '';
      }
      tmuxPlugins.cpu
      tmuxPlugins.battery
    ];
    shell = "${pkgs.zsh}/bin/zsh";
    shortcut = "a";
    terminal = "tmux-256color";
    tmuxp.enable = true;
  };
}
