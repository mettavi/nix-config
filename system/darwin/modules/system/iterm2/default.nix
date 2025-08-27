{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nyx.modules.system.apps.iterm2;
in
{
  options.nyx.modules.system.apps.iterm2 = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and setup iTerm2 on darwin";
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
  };
}
