{
  config,
  lib,
  secrets_path,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.devices.wdssd;
in
{
  options.mettavi.system.devices.wdssd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up a luks-encrypted WD ssd to auto-unlock and automount";
    };
  };

  config = mkIf cfg.enable {
    environment.etc.crypttab = {
      mode = "0600";
      text = ''
        # <volume-name> <encrypted-device> [key-file] [options]
        nixbak UUID=c8afcf0e-1642-4b85-a74b-9b8182a7f06a ${
          config.sops.secrets."users/${username}/wdssd.luks.key".path
        } noauto
      '';
    };

    # NB: In order to encrypt a binary file, the example command on the sops-nix repo did not work
    # This is the successful command:
    # cat secrets/wdssd.key | sops encrypt --filename-override secrets/wdssd.luks.key \
    # --input-type binary /dev/stdin > secrets/wdssd.luks.key
    sops.secrets = {
      "users/${username}/wdssd.luks.key" = {
        format = "binary";
        sopsFile = "${secrets_path}/secrets/wdssd.luks.key";
      };
    };
  };
}
