{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  programs.home-manager.enable = true;
  manual.html.enable = true;
  home.username = "${inputs.user}";
  home.homeDirectory = "/Users/timotheos";

  home.stateVersion = "23.11";

  # make programs use XDG directories whenever supported
  home.preferXdgDirectories = true;
  imports = [
    # sops config  for home
    ./sops-home.nix
    # packages
    ./packages/yazi.nix
  ];

  ######## INSTALL PACKAGES #########

  home.packages = with pkgs; [
    atuin
  ];

  services = {
    gpg-agent = {
      enable = true;
      extraConfig = ''
        pinentry-program /usr/local/bin/pinentry-touchid
      '';
    };
  };

  ######## CONFIGURE (AND INSTALL) PACKAGES USING NATIVE NIX OPTIONS ########

  programs = {
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
      extraConfig = (builtins.readFile ../tmux/.config/tmux/tmux.conf);
      historyLimit = 50000;
      keyMode = "vi";
      mouse = true;
      # tmux sensible plugin already included
      sensibleOnTop = false;
      terminal = "tmux-256color";
      tmuxp.enable = true;
    };
    vscode = {
      enable = true;
      # disallow extensions being installed or updated by vscode
      mutableExtensionsDir = false;
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;
      extensions = with pkgs.vscode-marketplace; [
        # https://raw.githubusercontent.com/nix-community/nix-vscode-extensions/master/data/cache/vscode-marketplace-latest.json
        dbaeumer.vscode-eslint
        formulahendry.code-runner
        ms-vscode-remote.remote-containers
        ritwickdey.liveserver
      ];
      # ++ (with pkgs.open-vsx; [
      # https://raw.githubusercontent.com/nix-community/nix-vscode-extensions/master/data/cache/open-vsx-latest.json
      # ]);
      keybindings = [
        {
          "key" = "ctrl+`";
          "command" = "workbench.action.terminal.focus";
          "when" = "editorTextFocus";
        }
        {
          "key" = "ctrl+`";
          "command" = "workbench.action.focusActiveEditorGroup";
          "when" = "terminalFocus";
        }
        {
          "key" = "ctrl+'";
          "command" = "workbench.action.terminal.toggleTerminal";
        }
      ];
      userSettings = {
        "editor.insertSpaces" = true;
        "editor.tabSize" = 2;
        "editor.autoIndent" = "advanced";
        "diffEditor.ignoreTrimWhitespace" = false;
        "editor.detectIndentation" = false;
        "extensions.autoUpdate" = false;
        "window.zoomLevel" = 1;
        "eslint.codeActionsOnSave.rules" = null;
        "editor.fontLigatures" = false;
        "terminal.integrated.fontFamily" = "MesloLGS Nerd Font Mono";
        "editor.fontFamily" = "MesloLGS Nerd Font Mono; Monaco; 'Courier New'; monospace";
        "update.mode" = "manual";
        "telemetry.telemetryLevel" = "off";
        "files.autoSave" = "afterDelay";
        "terminal.integrated.macOptionIsMeta" = true;
        "application.shellEnvironmentResolutionTimeout" = 30;
      };
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
      completionInit = (builtins.readFile ../zsh/.config/zsh/.zsh_completions);
      dotDir = ".config/zsh";
      envExtra = (builtins.readFile ../zsh/.config/zsh/.zshenv);
      history = {
        path = "$ZDOTDIR/.zsh_history";
        save = 100000;
        size = 100000;
      };
      initExtraFirst = (builtins.readFile ../zsh/.config/zsh/.zshrc_top);
      initExtra = (builtins.readFile ../zsh/.config/zsh/.zshrc);
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
      "zsh/.zsh_aliases".source = ../zsh/.config/zsh/.zsh_aliases;
    };
  };
  # link without copying to nix store (manage externally) - must use absolute paths
  # xdg.configFile.nvim.source = mkOutOfStoreSymlink "/Users/timotheos/.dotfiles/.config/nvim";

}
