{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nyx.modules.system.shells.bash;
in
{
  options.nyx.modules.system.shells.bash = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and enable recent version of bash on darwin";
    };
  };

  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;
      # this will enable and install bash-completion package (bash.enableCompletion is deprecated)
      completion.enable = true;
    };
  };
}
