{
  config,
  hostname,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.openssh;
in
{
  options.mettavi.system.services.openssh = {
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
      settings = {
        # forbid root login through SSH (may wish to override this for initial system setup)
        PermitRootLogin = "prohibit-password";
      };
    };
  };
}
