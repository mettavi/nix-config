{
  config,
  hostname,
  lib,
  osConfig,
  secrets_path,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.shell.atuin;
in
{
  options.mettavi.shell.atuin = {
    enable = mkEnableOption "Install and configure atuin for shell history";
  };

  config = mkIf cfg.enable {
    catppuccin = {
      # see color demos at https://github.com/catppuccin/catppuccin
      enable = true;
      # don't autoenable all the module's ports
      autoEnable = false;
      atuin = {
        enable = true;
        flavor = "macchiato";
        accent = "sapphire";
      };
    };

    programs.atuin = {
      enable = true;
      daemon = {
        enable = true;
        logLevel = "info";
      };
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableNushellIntegration = false;
      enableZshIntegration = config.mettavi.shell.zsh.setup;
      # NB: Atuin writes its default config file after every single shell command,
      # which can make it difficult to manually remove
      forceOverwriteSettings = true;
      settings = {
        ## enable or disable automatic sync
        auto_sync = true;
        ## If enabled, upon hitting enter Atuin will immediately execute the command,
        ## whereas tab will put the command in the prompt for editing.
        ## If set to false, both enter and tab will place the command in the prompt for editing.
        ## This applies for new installs. Old installs will keep the old behaviour unless configured otherwise.
        enter_accept = true;
        ## The list of enabled filter modes, in order of priority.
        ## The "workspace" mode is skipped when not in a workspace or workspaces = false.
        ## Default filter mode can be overridden with the filter_mode setting.
        filters = [
          "host"
          "global"
          "session"
          "workspace"
          "directory"
          "session-preload"
        ];
        session_path = config.sops.secrets."users/${username}/atuin/atuin_session_${hostname}".path;
        key_path = config.sops.secrets."users/${username}/atuin/atuin_key_${hostname}".path;
        ## how often to sync history. note that this is only triggered when a command
        ## is run, so sync intervals may well be longer
        ## set it to 0 to sync after every command
        sync_frequency = "5m";
        ## which search mode to use for interactive search
        ## possible values: prefix, fulltext, fuzzy, daemon-fuzzy
        search_mode = "daemon-fuzzy";
      };
    };
    # set up automatic server sync using atuin key and session tokens
    sops.secrets =
      let
        atuinSecrets.sopsFile = "${secrets_path}/secrets/apps/atuin.yaml";
      in
      {
        "users/${username}/atuin/atuin_key_${hostname}" = atuinSecrets;
        "users/${username}/atuin/atuin_session_${hostname}" = atuinSecrets;
      };
    # zsh function to search atuin shell history with fzf
    # xdg.configFile = {
    #   ".atuinrc".source = ../../../dots/atuin/.atuinrc;
    # };
  };
}
