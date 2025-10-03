{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.nyx.system.apps.iterm2;
in
{
  options.nyx.system.apps.iterm2 = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and setup iTerm2 on darwin";
    };
    transparency = mkOption {
      type = types.bool;
      default = true;
      description = "Make iterm2 (and dependencies) transparent";
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      # iterm2 brew updates are more recent compared to the nix package
      {
        name = "iTerm2";
        greedy = true;
      }
    ];
    system.defaults = {
      CustomUserPreferences = {
        # set iterm2 to write user prefs to custom file
        "com.googlecode.iterm2" = {
          "com.googlecode.iterm2.PrefsCustomFolder" = "$NIXFILES/home/shared/dots/iterm2";
          "com.googlecode.iterm2.LoadPrefsFromCustomFolder" = true;
        };
      };
    };
    home-manager.users.${username}.programs =
      mkIf config.home-manager.users.${username}.nyx.shell.tmux.enable
        {
          tmux = mkIf cfg.transparency {
            extraConfig = "set -g status-style bg=default";
            plugins = with pkgs.tmuxPlugins; [
              {
                plugin = catppuccin;
                extraConfig = "set -g @catppuccin_status_background \"default\"";
              }
            ];
          };
        };
  };
}
