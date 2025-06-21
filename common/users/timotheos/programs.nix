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
      };
      themes = {
        catppuccin-mocha = {
          background = "1e1e2e";
          cursor-color = "f5e0dc";
          foreground = "cdd6f4";
          palette = [
            "0=#45475a"
            "1=#f38ba8"
            "2=#a6e3a1"
            "3=#f9e2af"
            "4=#89b4fa"
            "5=#f5c2e7"
            "6=#94e2d5"
            "7=#bac2de"
            "8=#585b70"
            "9=#f38ba8"
            "10=#a6e3a1"
            "11=#f9e2af"
            "12=#89b4fa"
            "13=#f5c2e7"
            "14=#94e2d5"
            "15=#a6adc8"
          ];
          selection-background = "353749";
          selection-foreground = "cdd6f4";
        };
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
      baseIndex = 1;
      enable = true;
      escapeTime = 10;
      extraConfig = (builtins.readFile ../../../modules/tmux/tmux.conf);
      historyLimit = 50000;
      keyMode = "vi";
      mouse = true;
      # tmux sensible plugin already included
      sensibleOnTop = false;
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
