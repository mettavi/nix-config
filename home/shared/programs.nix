{
  config,
  hostname,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    fastfetch # neofetch-like sys info tool
  ];

  # install the HTML manual and "home-manager-help" command
  manual.html.enable = true;

  programs = {
    # ensure home-manager itself is installed
    home-manager.enable = true;
    aria2.enable = true;
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
      settings = {
        "github.com" = {
          identityFile = "${config.home.homeDirectory}/.ssh/${config.home.username}-${hostname}_ed25519";
          # Completely decouple GitHub from multiplexing rules
          controlMaster = "no";
        };
        "*.mettavi.cloud" = {
          # Speeds up high-latency setups by compressing text streams
          compression = true;
          # Stops slow cellular DNS lookups from stalling connection handshakes
          addressFamily = "inet";
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
          # Send a background ping every 15 seconds to keep a cellular tunnel open
          serverAliveInterval = 15;
          # Allow up to 4 missed pings (1 minute total) before giving up on a dead socket
          serverAliveCountMax = 4;
          # Let the OS track TCP connections alongside OpenSSH protocols
          tcpKeepAlive = true;
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
