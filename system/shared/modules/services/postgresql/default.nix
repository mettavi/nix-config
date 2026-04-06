{
  config,
  lib,
  username,
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
        # eg. "/var/lib/postgresql/17"
        dataDir = "/var/lib/postgresql/${config.services.postgresql.package.psqlSchema}";
        # peer authentication map, see pg_ident.conf in the nix store
        # NB: use "sudo -u postgres/immich psql -U postgres/immich" etc. to login with the default users
        identMap = # bash
          ''
            # map the root user to the pgsql "postgres" user (eg. allow "sudo psql -U postgres")
            postgres root postgres
          '';
        settings = {
          log_connections = true;
          logging_collector = true; # Enable capturing of stderr and csvlog into log file
          log_disconnections = true;
          log_destination = lib.mkForce "syslog"; # stderr, csvlog, syslog, and eventlog
          log_statement = "all"; # none, ddl, mod, all
          log_min_messages = "debug1"; # error, warning, notice, info, debug 1..5
          port = 5432;
        };
      };
    };
  };
}
