{
  config,
  lib,
  secrets_path,
  username,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.mettavi.system.devices.t7ssd;
in
{
  options.mettavi.system.devices.t7ssd = {
    enable = mkOption {
      type = bool;
      default = false;
      description = "Set up a luks-encrypted Samsung T7 nvme ssd to auto-unlock and automount";
    };
    backup-header = mkOption {
      type = bool;
      default = true;
      description = "Backup the luks header when the disk is mounted";
    };
  };

  config = mkIf cfg.enable {
    # automatically unlock the luks-encrypted disk with a keyfile
    # NB: Linux uses the mapper name to refer to the unlocked LUKS
    # disk/partition (eg. sdb[1]) (see /dev/mapper)
    environment.etc.crypttab = {
      mode = "0600";
      text = ''
        # <mapper-name> <encrypted-device> [key-file] [options]
        t7-luks UUID=28f7ca78-bbc5-4c36-a41f-ea4b0cf732f1 ${
          config.sops.secrets."users/${username}/t7ssd.luks.key".path
        } luks,noauto,nofail
      '';
    };

    # Create a keyfile with: dd if=/dev/urandom of=/path/to/keyfile bs=4096 count=1, and chmod 0400
    # Then add it to the device with: cryptsetup luksAddKey /dev/sdX /path/to/keyfile

    # NB: In order to encrypt a binary file, the example command on the sops-nix repo did not work
    # This is the successful procedure:
    # 1. add a rule to .sops.yaml, eg. - path_regex: secrets/t7ssd\.luks\.key$
    # 2. execute command: cat secrets/wdssd.key | sops encrypt --filename-override secrets/wdssd.luks.key \
    # --input-type binary /dev/stdin > secrets/wdssd.luks.key
    sops.secrets = {
      # key file to automatically decrypt the drive when plugged in
      "users/${username}/t7ssd.luks.key" = {
        format = "binary";
        sopsFile = "${secrets_path}/secrets/devices/t7ssd/t7ssd.luks.key";
      };
      # password to encrypt the luks-header backup with openssl
      "users/${username}/t7-ssl-encpass" = {
        sopsFile = "${secrets_path}/secrets/devices/t7ssd/t7-ssl-encpass.yaml";
      };
    };
  };
}
