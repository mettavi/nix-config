{
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  # install the HTML manual and "home-manager-help" command
  manual.html.enable = true;

  home = {
    username = "timotheos";
    homeDirectory = "/Users/timotheos";
    stateVersion = "23.11";
    # make programs use XDG directories whenever supported
    preferXdgDirectories = true;
  };

  imports = [
    # sops config  for home
    ../../modules/sops/sops-home.nix
    # packages
    ../../common/users/timotheos/vscode.nix
    ../../modules/yazi.nix
  ];

  ######## INSTALL SERVICES #########

  services = {
    gpg-agent = {
      enable = true;
      extraConfig = ''
        pinentry-program /usr/local/bin/pinentry-touchid
      '';
    };
  };

  ######## INSTALL PACKAGES #########

  home.packages = with pkgs; [
    atuin
  ];

  ######## CONFIGURE (AND INSTALL) PACKAGES USING NATIVE NIX OPTIONS ########

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
      keys = [ "id_ed25519" ];
    };
    lazygit.enable = true;
    # provides nix-locate and command-not-found commands
    nix-index.enable = true;
    neovim.enable = true;
    # pyenv.enable = true;
    # rbenv.enable = true;
    ripgrep.enable = true;
    thefuck.enable = true;
    tmux = {
      baseIndex = 1;
      enable = true;
      escapeTime = 10;
      extraConfig = (builtins.readFile ../../modules/tmux/.config/tmux/tmux.conf);
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
    zsh = {
      enable = true;
      antidote = {
        enable = true;
        plugins = [
          "Aloxaf/fzf-tab"
          "olets/zsh-autosuggestions-abbreviations-strategy"
          "MichaelAquilina/zsh-you-should-use"
        ];
      };
      autosuggestion.enable = true;
      completionInit = (builtins.readFile ../../modules/zsh/.config/zsh/.zsh_completions);
      dotDir = ".config/zsh";
      envExtra = (builtins.readFile ../../modules/zsh/.config/zsh/.zshenv);
      history = {
        path = "$ZDOTDIR/.zsh_history";
        save = 100000;
        size = 100000;
      };
      initExtraFirst = (builtins.readFile ../../modules/zsh/.config/zsh/.zshrc_top);
      initExtra = (builtins.readFile ../../modules/zsh/.config/zsh/.zshrc);
      sessionVariables = {
        # alias for thefuck command
        TF_ALIAS = "oh";
      };
      syntaxHighlighting.enable = true;
      zsh-abbr.enable = true;
    };
    # tmux = import ../home/tmux.nix { inherit pkgs; };
    # zsh = import ../home/zsh.nix { inherit config pkgs; };
    # #zoxide = (import ../home/zoxide.nix { inherit config pkgs; });
    # fzf = import ../home/fzf.nix { inherit pkgs; };

  };
  ####### CONFIGURE PACKAGES USING DOTFILES ########

  # link config file or whole directory to ~
  # home.file."foo".source = ./bar;

  # link the contents of a directory to ~
  # home.file."bin" = {
  #   source = ./bin;
  #   recursive = true;
  #   executable = true;
  # };

  # link config file/directory to ~/.config (use "recursive" for dir contents)
  # xdg = {
  #   enable = true;
  #   configFile."foo" = {
  #     source = ./bar;
  #   };
  # };

  xdg = {
    # enable management of xdg base directories
    enable = true;
    configFile = {
      "zsh/.zsh_aliases".source = ../../modules/zsh/.config/zsh/.zsh_aliases;
    };
  };
  # link without copying to nix store (manage externally) - must use absolute paths
  # xdg.configFile.nvim.source = mkOutOfStoreSymlink "${config.users.users.ta.home}.dotfiles/.config/nvim";

}
