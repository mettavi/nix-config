{
  config,
  hostname,
  inputs,
  nix_repo,
  pkgs,
  ...
}:
{
  imports = [ ./calibre-and-sync.nix ];

  home.packages = with pkgs; [
    atuin
    # Bash and zsh key bindings for Git objects, powered by fzf
    fzf-git-sh
    rclone # sync files and directories to and from major cloud storage
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
    git = {
      enable = true;
      # delta.enable = true;
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
      settings = {
        user = {
          email = inputs.secrets.email.gitHub;
          name = inputs.secrets.name;
        };
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
          # NB: ssh-agent must be started, eg. using nixos startAgent option (enabled by default on darwin)
          # NB: this is not required if the keychain utility is installed
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          # more robust settings for control* options (especially a shorter controlPath value)
          controlMaster = "auto"; # use an existing ssh connection if available
          controlPath = "~/.ssh/master-%C";
          controlPersist = "10m";
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
