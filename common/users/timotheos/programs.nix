{
  user1,
  pkgs,
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
          identityFile = "/Users/${user1}/.config/sops-nix/secrets/users/${user1}/ssh_keys/${user1}_ed25519";
          extraOptions = {
            IgnoreUnknown = "UseKeyChain";
            UseKeyChain = "yes";
          };
        };
        "nixos-ocloud" = {
          hostname = "207.211.158.25";
          user = "ubuntu";
          identityFile = "/Users/${user1}/.config/sops-nix/secrets/users/${user1}/ssh_keys/ssh-nixos-ocloud.key";
        };
      };
    };

    thefuck = {
      enable = true;
      enableZshIntegration = true;
      # this feature is experimental and did not work with powerlevel 10k prompt
      # Error was: "[WARN] PS1 doesn't contain user command mark, 
      # please ensure that PS1 is not changed after The Fuck alias initialization"
      # enableInstantMode = true;
      alias = "oh";
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
