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
  };

  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      historyFile = "${config.xdg.configHome}/bash/.bash_history";
    };
  };
}
