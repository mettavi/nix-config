{
  config,
  hostname,
  lib,
  nix_repo,
  pkgs,
  username,
  ...
}:
{

  home.packages = with pkgs; [
    atuin
    # Bash and zsh key bindings for Git objects, powered by fzf
    fzf-git-sh
  ];

  programs = {
    # ensure home-manager itself is installed
    home-manager.enable = true;
    aria2.enable = true;
    # atuin.enable = true;
    bash = {
      enable = true;
      enableCompletion = true;
      historyFile = "${config.xdg.configHome}/bash/.bash_history";
    };
    bat.enable = true;
    eza = {
      enable = true;
      enableZshIntegration = false;
    };
    fd.enable = true;
    fzf = {
      enable = true;
    };
    # install ghostty on nixOS only
    ghostty = lib.mkIf (!pkgs.stdenv.isDarwin) {
      enable = true;
      # integration will work in more scenarios, such as switching shells
      enableZshIntegration = true;
      # settings will be written to $XDG_CONFIG_HOME/ghostty/config
      settings = {
        font-family = "MesloLGS Nerd Font Mono Regular";
        font-size = "20";
        theme = "iTerm2 Pastel Dark Background";
      };
    };
    git = {
      enable = true;
      delta.enable = true;
      # enable automatic maintenance of git repos using launchd/systemd
      maintenance = {
        enable = true;
        repositories = [ "${config.home.homeDirectory}/${nix_repo}" ];
        timers = {
          daily = "Tue..Sun *-*-* 0:53:00";
          hourly = "*-*-* 1..23:53:00";
          weekly = "Mon 0:53:00";
        };
      };
    };
    java = {
      enable = true;
      package = pkgs.zulu; # Certified builds of OpenJDK
    };
    jq.enable = true;
    keychain = {
      enable = true;
      enableZshIntegration = true;
      keys = [ "${username}-${hostname}_ed25519" ];
    };
    lazygit.enable = true;
    # provides nix-locate and command-not-found commands
    nix-index.enable = true;
    neovim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        noice-nvim
        telescope-fzf-native-nvim
      ];
    };
    # pyenv.enable = true;
    # rbenv.enable = true;
    ripgrep.enable = true;

    ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          identityFile = "${config.xdg.configHome}/sops-nix/secrets/users/${username}/ssh_keys/${username}-${hostname}_ed25519";
          extraOptions = {
            IgnoreUnknown = "UseKeyChain";
            UseKeyChain = "yes";
          };
        };
        "nixos-ocloud" = {
          hostname = "207.211.158.25";
          user = "ubuntu";
          identityFile = "${config.xdg.configHome}/sops-nix/secrets/users/${username}/ssh_keys/ssh-nixos-ocloud.key";
        };
      };
    };

    # Terminal command correction, alternative to thefuck, written in Rust
    pay-respects = {
      enable = true;
      enableZshIntegration = true;
    };

    tmux = {
      enable = true;
      baseIndex = 1;
      customPaneNavigationAndResize = true;
      escapeTime = 10;
      extraConfig = # sh
        ''
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
        '';
      historyLimit = 50000;
      keyMode = "vi";
      mouse = true;
      newSession = true;
      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin_window_left_separator ""
            set -g @catppuccin_window_right_separator " "
            set -g @catppuccin_window_middle_separator " █"
            set -g @catppuccin_window_number_position "right"
            set -g @catppuccin_window_default_fill "number"
            set -g @catppuccin_window_default_text "#W"
            set -g @catppuccin_window_current_fill "number"
            set -g @catppuccin_window_current_text "#W#{?window_zoomed_flag,(),}"
            set -g @catppuccin_status_modules_right "directory date_time"
            set -g @catppuccin_status_modules_left "session"
            set -g @catppuccin_status_left_separator  " "
            set -g @catppuccin_status_right_separator " "
            set -g @catppuccin_status_right_separator_inverse "no"
            set -g @catppuccin_status_fill "icon"
            set -g @catppuccin_status_connect_separator "no"
            set -g @catppuccin_directory_text "#{b:pane_current_path}"
            set -g @catppuccin_date_time_text "%H:%M"
          '';
        }
      ];
      shell = "${pkgs.zsh}/bin/zsh";
      shortcut = "a";
      terminal = "tmux-256color";
      tmuxp.enable = true;
    };
    yt-dlp.enable = true;
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };

  };
}
