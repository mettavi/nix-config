{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.postgresql;
in
{
  options.mettavi.system.services.postgresql = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure the postgresql service";
    };
  };

  config = mkIf cfg.enable {
    services = {
      postgresql = {
        enable = true;
        # CRITICAL: Forces Postgres to actually bind network sockets globally
        enableTCPIP = mkForce true;
        # --- THE DEFINITIVE FIX ---
        # This forces PostgreSQL to append this setting to the absolute bottom of the generated
        # .conf file, successfully overriding the hardcoded 'localhost' logic above it.
        extraConfig = lib.mkForce ''
          listen_addresses = '*'
        '';
        # eg. "/var/lib/postgresql/17"
        dataDir = "/var/lib/postgresql/${config.services.postgresql.package.psqlSchema}";

        # Authorize the specific 10.89 subnet pool (for podman paperless) to log in
        authentication = mkForce ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     trust
          host    all             all             127.0.0.1/32            scram-sha-256
          host    all             all             10.89.0.0/24            password
        '';

        # peer authentication map, see pg_ident.conf in the nix store
        # NB: use "sudo -u postgres/immich psql -U postgres/immich" etc. to login with the default users
        identMap = # bash
          mkForce ''
            # map the root user to the pgsql "postgres" user (eg. allow "sudo psql -U postgres")
            postgres root postgres
            postgres paperless paperless
          '';
        # configure the postgresql.conf file
        settings = {
          listen_addresses = lib.mkForce "*";
          log_connections = true;
          logging_collector = true; # Enable capturing of stderr and csvlog into log file
          log_disconnections = true;
          log_destination = mkForce "syslog"; # stderr, csvlog, syslog, and eventlog
          log_statement = "all"; # none, ddl, mod, all
          log_min_messages = "debug1"; # error, warning, notice, info, debug 1..5
          port = 5432;
          # WAL ARCHIVING
          # 'replica' or higher is required for archiving
          wal_level = "replica";
          archive_mode = "on";
          # archived per 16 MB WAL segment (by default) AND 15 mins
          archive_timeout = 900; # 15 minutes in seconds
          # %p: The path to the "live" WAL segment Postgres just finished (source in its internal pg_wal directory).
          # %f: The filename of that segment (destination).
          archive_command =
            let
              # Get the absolute path to the data directory from config
              dataDir = config.services.postgresql.dataDir;
              testBin = "${pkgs.coreutils}/bin/test";
              cpBin = "${pkgs.coreutils}/bin/cp";
              archiveDir = "/var/backup/postgresql/archive";
            in
            # Note the use of ${dataDir}/%p to force an absolute path
            "${testBin} ! -f ${archiveDir}/%f && ${cpBin} ${dataDir}/%p ${archiveDir}/%f";

          # COMMANDS TO ENABLE DURING A RESTORE
          # Command to fetch logs from your archive during recovery
          # restore_command = "cp /var/backup/postgresql/archive/%f %p";
          # The "Target": Restore to 1 minute before the mistake happened
          # recovery_target_time = "2024-05-20 14:04:59";
          # Tells Postgres to become the primary DB once it hits the target
          # recovery_target_action = "promote";
        };
      };
    };

    systemd.services.postgresql = {
      serviceConfig = {
        # IMPORTANT: Allow postgres to write to the backup path
        ReadWritePaths = [ "/var/backup/postgresql/archive" ];
      };
    };

    systemd.services.monitor-pg-archive = {
      description = "Log PostgreSQL archive size for monitoring";
      serviceConfig.Type = "oneshot";
      script = ''
        size=$(du -sh /var/backup/postgresql/archive | cut -f1)
        count=$(ls /var/backup/postgresql/archive | wc -l)
        echo "PostgreSQL WAL Archive Status: Size=$size, FileCount=$count"
      '';
      startAt = "hourly";
    };

    # Ensure the archive directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d /var/backup/postgresql/archive 0750 postgres postgres -"
    ];
  };
}
