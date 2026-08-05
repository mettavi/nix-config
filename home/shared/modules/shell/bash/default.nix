{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.shell.bash;
in
{
  options.mettavi.shell.bash = {
    enable = mkEnableOption "bash configuration";
    prompt = mkOption {
      type = types.enum [
        "manual"
        "oh-my-posh"
        "p10k"
      ];
      default = "manual";
      description = "Set the shell prompt";
    };
  };

  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      historyFile = "${config.xdg.configHome}/bash/.bash_history";
    };
    programs.oh-my-posh = mkIf (cfg.prompt == "oh-my-posh") {
      enable = true;
      configFile = ../../../dots/oh-my-posh/gruvbox.json;
      enableBashIntegration = true;
    };
  };
}
