{
  config,
  hostname,
  lib,
  ...
}:
with lib;
let
  cfg = config.nyx.modules.system.openssh;
in
{
  options.nyx.modules.system.openssh = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the ssh server on the system";
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      # create a host key if one doesn't exist
      hostKeys = [
        {
          comment = "root@${hostname}";
          path = "/etc/ssh/ssh_${hostname}_ed25519_key";
          rounds = 100;
          type = "ed25519";
        }
      ];
      # settings = {
      # options to harden openssh, especially for servers
      # forbid the use of ssh password authentication
      # PasswordAuthentication = mkDefault false;
      # forbid root login through SSH
      # PermitRootLogin = "no";
      # };
    };
  };
}
