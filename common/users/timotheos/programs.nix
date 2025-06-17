{
  config,
  hostname,
  nix_repo,
  pkgs,
  username,
  ...
}:
{

  home.packages = with pkgs; [
    atuin
  ];

  programs = {
    # ensure home-manager itself is installed
    home-manager.enable = true;
    aria2.enable = true;
    # atuin.enable = true;
    bash = {
      enable = true;
      historyFile = "$HOME/.config/bash/.bash_history";
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
      keys = [ "timotheos_ed25519" ];
    };
    lazygit.enable = true;
    # provides nix-locate and command-not-found commands
    nix-index.enable = true;
    neovim.enable = true;
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
      extraConfig = (builtins.readFile ../../../modules/tmux/.config/tmux/tmux.conf);
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
    # tmux = import ../home/tmux.nix { inherit pkgs; };
    # zsh = import ../home/zsh.nix { inherit config pkgs; };
    # #zoxide = (import ../home/zoxide.nix { inherit config pkgs; });
    # fzf = import ../home/fzf.nix { inherit pkgs; };

  };
}
