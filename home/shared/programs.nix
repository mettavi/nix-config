{
  config,
  hostname,
  inputs,
  nix_repo,
  pkgs,
  ...
}:
let
  homeDir = "${config.home.homeDirectory}";
in
{
  home.packages = with pkgs; [
    atuin
    fastfetch # neofetch-like sys info tool
    # Bash and zsh key bindings for Git objects, powered by fzf
    fzf-git-sh
  ];

  programs = {
    # ensure home-manager itself is installed
    home-manager.enable = true;
    aria2.enable = true;
    # atuin.enable = true;
    bat.enable = true;
    delta = {
      enable = true;
      enableGitIntegration = true;
    };
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
    java = {
      # Certified builds of OpenJDK (with JavaFX included for Pali Platform app)
      enable = true;
      package = pkgs.zulu.override { enableJavaFX = true; };
    };
    jq.enable = true;
    # manage ssh-agent and ssh-add automatically and extend caching to once per system login
    # NB: this works cross-platform and doesn't depend on macOS-specific "UseKeyChain" option in ssh config
    keychain = {
      enable = true;
      # do not attempt to start gpg-agent, which is currently not installed
      # NB: This option is deprecated as of v 2.9.0, as gpg-agent is no longer started by default
      # agents = [ "ssh" ];
      enableZshIntegration = true;
      keys = [ "${config.home.username}-${hostname}_ed25519" ];
    };
    lazygit.enable = true;
    # pyenv.enable = true;
    # rbenv.enable = true;
    ripgrep.enable = true;

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "github.com" = {
          identityFile = "${config.home.homeDirectory}/.ssh/${config.home.username}-${hostname}_ed25519";
        };
        "*" = {
          forwardAgent = false;
          # add ssh keys to ssh-agent when making the first connection
          # (helpful for caching passphrases and finding non-standard key names)
          # NB: ssh-agent must be started, eg. using NIXOS startAgent option (enabled by default on darwin)
          # NB: this is not required if the keychain utility is installed
          addKeysToAgent = "no";
          compression = false;
          # more robust settings for control* options (especially a shorter controlPath value)
          controlMaster = "auto"; # use an existing ssh connection if available
          controlPath = "~/.ssh/master-%C";
          controlPersist = "10m";
          hashKnownHosts = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          userKnownHostsFile = "~/.ssh/known_hosts";
        };
      };
    };

    # Terminal command correction, alternative to thefuck, written in Rust
    # default alias is "f"
    # by default, links to command_not_found script from nix-index package if it is installed
    # (no need to enable via programs.nix-index separately)
    # --nocnf: Disables command_not_found handler (add via pay-respects.settings)
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
