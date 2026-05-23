{
  config,
  lib,
  secrets_path,
  username,
  utils,
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
    systemd.services.backup-luks-headers =
      let
        mountPath = "/run/media/${username}/backup";
      in
      mkIf cfg.backup-header {
        description = "Backup luks headers on encrypted Samsung T7 disk";
        # bindsTo tells systemd: "The thing I depend on is gone, I should stop immediately."
        bindsTo = [ "${utils.escapeSystemdPath "${mountPath}"}.mount" ];
        after = [ "${utils.escapeSystemdPath "${mountPath}"}.mount" ];
        wantedBy = [ "${utils.escapeSystemdPath "${mountPath}"}.mount" ];
        before = [ "restic-backups-oona" ];
        requiredBy = [ "restic-backups-oona" ];
        path = with pkgs; [
          coreutils
          findutils
          openssl
          util-linux
        ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          # MOUNT GUARD: Check if the path is actually a mount point
          if ! ${pkgs.util-linux}/bin/mountpoint -q "${mountPath}"; then
            echo "ERROR: ${mountPath} is not a mount point. Aborting to save root partition."
            exit 255
          fi

          BACKUP_DIR="/var/backup/luks-backups"
          DATE=$(date +%Y%m%d)
          RETENTION_DAYS=90
          mkdir -p "$BACKUP_DIR"

          # Back up all LUKS devices
          for dev in $(blkid -t TYPE=crypto_LUKS -o device 2>/dev/null); do
            SAFE_NAME=$(echo "$dev" | tr '/' '_')
            BACKUP_FILE="''${BACKUP_DIR}/luks-header''${SAFE_NAME}-''${DATE}.img"
            INFO_FILE="''${BACKUP_DIR}/luks-info''${SAFE_NAME}-''${DATE}.txt"

            echo "Backing up and encrypting header for $dev..."

            cryptsetup luksHeaderBackup "$dev" \
            | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -pass file:${
              config.sops.secrets."users/${username}/t7-ssl-encpass".path
            } -out "$BACKUP_FILE"

              # Save device information
            {
              echo "LUKS Header Backup Information"
              echo "=============================="
              echo "Date: $(date)"
              echo "Device: $dev"
              echo "Hostname: $(hostname)"
              echo ""
              echo "--- blkid output ---"
              blkid "$dev"
              echo ""
              echo "--- LUKS Dump ---"
              cryptsetup luksDump "$dev"
              echo ""
              echo "--- lsblk output ---"
              lsblk "$dev"
            } > "$INFO_FILE"

            echo "  Header: $BACKUP_FILE"
            echo "  Info:   $INFO_FILE"

            if [ $? -eq 0 ]; then
              # gpg --batch --yes --pinentry-mode loopback \
              # --symmetric --cipher-algo AES256 \
              # --passphrase-file /root/.luks-backup-passphrase \
              # "$BACKUP_FILE" 2>/dev/null
              # shred -u "$BACKUP_FILE"
              logger -t luks-backup "Backed up LUKS header for $dev"
            else
              logger -t luks-backup -p err "Failed to back up LUKS header for $dev"
            fi
          done

          echo ""
          echo "All LUKS headers backed up to $BACKUP_DIR"

          # Clean up old backups
          find "$BACKUP_DIR" -name "luks-header*.img.gpg" -mtime +''${RETENTION_DAYS} -delete
        '';
      };
  };
}
