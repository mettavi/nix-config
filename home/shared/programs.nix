{
  config,
  hostname,
  inputs,
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
  # import program submodules
  imports = [ ./programs ];

  programs = {
    # ensure home-manager itself is installed
    home-manager.enable = true;
    aria2.enable = true;
    # atuin.enable = true;
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
      extraConfig = {
        credential = lib.mkIf pkgs.stdenv.isDarwin {
          helper = "osxkeychain";
        };
      };
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
      userEmail = inputs.secrets.email.gitHub;
      userName = inputs.secrets.name;
    };
    java = {
      enable = true;
      package = pkgs.zulu; # Certified builds of OpenJDK
    };
    jq.enable = true;
    # keychain = {
    #   enable = true;
    #   enableZshIntegration = true;
    #   keys = [ "${username}-${hostname}_ed25519" ];
    # };
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
      # help ssh find keys with non-standard ssh key names when reconnecting, especially when using nixos-anywhere
      # NB: ssh-agent is started using nixos startAgent option
      addKeysToAgent = "yes";
      # more robust settings for control* options (especially a shorter controlPath value)
      controlMaster = "auto";
      controlPath = "~/.ssh/master-%C";
      controlPersist = "10m";
      matchBlocks = {
        "github.com" = {
          identityFile = "${config.home.homeDirectory}/.ssh/${username}-${hostname}_ed25519";
        };
        "salina" = {
          hostname = "169.224.231.109";
          user = "timotheos";
          identityFile = "${config.home.homeDirectory}/.ssh/${username}-${hostname}_ed25519";
        };
        "*" = {
          extraOptions = {
            # ignore macOS only option in linux
            IgnoreUnknown = "UseKeychain";
            UseKeychain = "yes";
          };
        };
      };
    };

    # Terminal command correction, alternative to thefuck, written in Rust
    # default alias is "f"
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
