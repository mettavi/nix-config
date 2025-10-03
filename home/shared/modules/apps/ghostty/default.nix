{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nyx.apps.ghostty;
in
{
  options.nyx.apps.ghostty = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure ghostty";
    };
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      # integration will work in more scenarios, such as switching shells
      enableZshIntegration = true;
      # settings will be written to $XDG_CONFIG_HOME/ghostty/config
      settings = {
        font-size = "18";
        # make right_alt send an escape sequence in ghostty
        macos-option-as-alt = true;
        # start windows maximized
        maximize = true;
        shell-integration-features = "sudo";
        theme = "iTerm2 Pastel Dark Background";
      };
    };
  };
}
