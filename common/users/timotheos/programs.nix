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

  imports = [ ./programs ];

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
      tmux = {
        # Sets FZF_TMUX=1, enabling fzf in tmux popups
        enableShellIntegration = true;
        # open in popup windows in 80% width, 60% height
        shellIntegrationOptions = [ "-p 80%,60%" ];
      };
    };
    # install ghostty on nixOS only
    ghostty = lib.mkIf (!pkgs.stdenv.isDarwin) {
      enable = true;
      # integration will work in more scenarios, such as switching shells
      enableZshIntegration = true;
      # settings will be written to $XDG_CONFIG_HOME/ghostty/config
      settings = {
        font-size = "18";
        # make right_alt send an escape sequence in ghostty
        keybind = [
          "unconsumed:alt+b=esc:b"
          "unconsumed:alt+f=esc:f"
        ];
        macos-option-as-alt = true;
        # start windows maximized
        maximize = true;
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
