{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.postgresql;
in
{
  options.mettavi.system.services.postgresql = {
    backup = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable db backup systemd services";
    };
  };

  config = mkIf (cfg.enable && cfg.backup) {
    services = {
      postgresqlBackup = {
        enable = true;
        # uses pg_dumpall
        backupAll = config.services.postgresqlBackup.databases == [ ];
        # restic dedupe works better without compression
        compression = "none";
        compressionLevel = 6;
        databases = [
          "immich"
          "paperless"
        ];
        location = "/var/backup/postgresql";
        pgdumpOptions = "--clean --if-exists";
        pgdumpAllOptions = "";
        # execute with the restic service rather than scheduling
        startAt = "";
      };
    };
  };
}
