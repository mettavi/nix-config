{
  config,
  hostname,
  lib,
  secrets_path,
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
    catppuccin = mkIf config.catppuccin.enable {
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
        enter_accept = true;
        ## which filter mode to use for interactive search
        ## possible values: "global", "host", "session", "session-preload", "directory", "workspace"
        ## consider using search.filters to customize the enablement and order of filter modes
        filter_mode = "host";
        keymap_mode = "vim-normal";
        ## which search mode to use for interactive search
        ## possible values: prefix, fulltext, fuzzy, daemon-fuzzy
        search_mode = "daemon-fuzzy";
        ## The list of enabled filter modes, in order of priority.
        ## The "workspace" mode is skipped when not in a workspace or workspaces = false.
        ## Default filter mode can be overridden with the filter_mode setting.
        # NB: Toggle the filter mode using CTRL-r
        search = {
          filters = [
            "host"
            "global"
            "session"
            "workspace"
            "directory"
            "session-preload"
          ];
        };
        session_path =
          config.sops.secrets."users/${config.home.username}/atuin/atuin_session_${hostname}".path;
        key_path = config.sops.secrets."users/${config.home.username}/atuin/atuin_key_${hostname}".path;
        tmux = {
          # Enable using atuin with tmux popup (requires tmux >= 3.2)
          # When enabled and running inside tmux, Atuin will use a popup window for interactive search.
          enabled = true;
        };
      };
    };
    # set up automatic server sync using atuin key and session tokens
    sops.secrets =
      let
        atuinSecrets.sopsFile = "${secrets_path}/secrets/apps/atuin.yaml";
      in
      {
        "users/${config.home.username}/atuin/atuin_key_${hostname}" = atuinSecrets;
        "users/${config.home.username}/atuin/atuin_session_${hostname}" = atuinSecrets;
      };
    # zsh function to search atuin shell history with fzf
    # programs.zsh.initContent = (builtins.readFile ./.atuinrc);
  };
}
