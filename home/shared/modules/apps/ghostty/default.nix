{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.apps.ghostty;
in
{
  options.mettavi.apps.ghostty = {
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
        background-opacity = 0.8; # default is 1 (fully opaque)
        # blur is not supported on gnome without the blur my shell extension
        # background-blur = 20;
        font-size = "14";
        # make right_alt send an escape sequence in ghostty
        macos-option-as-alt = true;
        # start windows maximized
        maximize = true;
        shell-integration-features = "sudo";
        theme = "iTerm2 Pastel Dark Background";
      };
    };
    xdg.terminal-exec = {
      enable = true;
      settings = {
        default = [
          "ghostty.desktop"
        ];
      };
    };
  };
}
