{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
{
  environment.etc = mkIf config.home-manager.users.${username}.nyx.modules.shell.tmux.enable {
    # pam_reattach.so re-enables pam_tid.so in tmux
    "pam.d/sudo_local".text = # bash
      ''
        # Managed by Nix Darwin
        auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
        auth       sufficient     pam_tid.so
      '';
  };
}
