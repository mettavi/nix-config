{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
{
  config = lib.mkIf config.home-manager.users.${username}.nyx.shell.tmux.enable {
    environment = {
      systemPackages = with pkgs; [ pam-reattach ];
      etc = {
        "pam.d/sudo_local".text = # bash
          ''
            # pam_reattach.so re-enables pam_tid.so in tmux
               # Managed by Nix Darwin
               auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
               auth       sufficient     pam_tid.so
          '';
      };
    };
  };
}
