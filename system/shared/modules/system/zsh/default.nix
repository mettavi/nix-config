{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.nyx.modules.system.shells.zsh;
  zsh_cfg = config.home-manager.users.${username}.nyx.modules.shell.zsh;
in
{
  options.nyx.modules.system.shells.zsh = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable zsh on the system";
    };
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      # required for completion of system packages
      enableCompletion = true;
      # initialise p10k prompt if selected
      promptInit =
        (optionalString (zsh_cfg.prompt == "p10k"))
          "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}
