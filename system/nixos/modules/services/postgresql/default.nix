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
    environment.systemPackages = [
      # NB: This script is useful when the system version of glibc changes,
      # which leads to warnings from postgres to refresh its DBs
      (pkgs.writeShellScriptBin "pg-fix-collation" ''
        set -e
        echo "Refreshing PostgreSQL collations and reindexing all accessible databases..."

        PSQL="${config.services.postgresql.package}/bin/psql -U postgres"

        # Query all databases that allow connections (includes template1, excludes template0)
        DBS=$(${config.services.postgresql.package}/bin/psql -U postgres -t -A -c "SELECT datname FROM pg_database WHERE datallowconn = true;")

        for db in $DBS; do
          echo "--------------------------------------------------"
          echo "Processing database: $db"

          # 1. Limit connections to 0 (blocks apps, permits superuser)
          $PSQL -d postgres -c "ALTER DATABASE \"$db\" WITH CONNECTION LIMIT 0;" > /dev/null

          # 2. Terminate active client connections
          $PSQL -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$db' AND pid <> pg_backend_pid();" > /dev/null

          # 3. Perform maintenance
          $PSQL -d "$db" -c "REINDEX DATABASE \"$db\";"
          $PSQL -d "$db" -c "ALTER DATABASE \"$db\" REFRESH COLLATION VERSION;"

          # 4. Restore default connection limit (-1 = unlimited)
          $PSQL -d postgres -c "ALTER DATABASE \"$db\" WITH CONNECTION LIMIT -1;" > /dev/null
        done

        echo "--------------------------------------------------"
        echo "Collation refresh complete! All databases isolated and updated safely."
      '')
    ];

    services = {
      postgresql = {
        enable = true;
        # CRITICAL: Forces Postgres to actually bind network sockets globally
        enableTCPIP = mkForce true;
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
          # none, ddl (schema changes), mod (plus data modifications), all
          log_statement = "none";
          log_min_messages = "warning"; # error, warning, notice, info, debug 1..5
          # stderr = Let PostgreSQL handle its own files instead of pushing to syslog
          log_destination = "stderr"; # stderr, csvlog, syslog, and eventlog
          # rotate the postgresql logs (if logging to stderr rather than syslog)
          log_filename = "postgresql-%Y-%m-%d_%H%M%S.log";
          log_truncate_on_rotation = true;
          log_rotation_age = 1440; # Rotate daily (1440 minutes)
          log_rotation_size = 10240; # Rotate if file reaches 10MB
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
