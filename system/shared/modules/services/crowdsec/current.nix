/*
  MIGRATION GOTCHAS ON REMUS
  Data moves. The old database lived in /var/lib/crowdsec/state/, and the new default is /var/lib/crowdsec/data/crowdsec.db.
  If you use a Traefik bouncer for Pangolin, its API key lives in the old database,
  so a fresh start means re-adding it with cscli bouncers add and updating the key in Traefik.

  Migrating instead. You can move the old crowdsec.db and the two credentials files into data/.
  A moved database that has a machine named remus plus a missing local_api_credentials.yaml makes cscli machines add fail,
  because the name already exists. The credentials files must move together with the database.

  Stale bouncer state. /var/lib/crowdsec-firewall-bouncer-register is currently a symlink into private/,
  and the new module manages it with a tmpfiles d rule. Several people in the PR thread had to remove stale private/ leftovers,
  so before the upgrade stop the services and rm both the symlink and /var/lib/private/crowdsec-firewall-bouncer-register.
  The new register script re-registers automatically if the API key file is missing.

  /etc/crowdsec is fully generated. Deleting it before the first switch avoids stale symlinks from the old module, as testers in the thread did.
*/
{
  config,
  hostname,
  lib,
  secrets_path,
  username,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    types
    ;
  cfg = config.mettavi.system.services.crowdsec;
  dataDir = config.services.crowdsec.settings.config.config_paths.data_dir;
  pangolin-traefik = config.mettavi.system.services.pangolin;
in
{
  options.mettavi.system.services.crowdsec = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and set up the CrowdSec detection engine";
    };
  };

  config = mkIf cfg.enable {
    services.crowdsec = {
      enable = true;
      autoUpdateService = true; # optional: daily `cscli hub update`

      hub.collections = [
        "crowdsecurity/linux"
      ]
      ++ lib.optionals pangolin-traefik.enable [
        "crowdsecurity/traefik" # parsers + scenarios for Traefik access logs
      ];
      # Add more later, e.g. "crowdsecurity/http-cve";

      # readOnlyPaths = [ "/var/log/traefik" ];  # if you acquire logs from files

      settings = {
        # list of data sources to be parsed
        acquisitions = [
          {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            labels.type = "syslog";
          }
        ]
        ++ lib.optionals pangolin-traefik.enable [
          {
            source = "file";
            filenames = [ "/var/log/traefik/access.log" ];
            labels.type = "traefik";
          }
        ];
        # Required for enrollment, and the default is null
        config = {
          api.server = {
            listen_uri = "0.0.0.0:8085";
            online_client.credentials_path = "${dataDir}/online_api_credentials.yaml";
          };
        };
        console = {
          enrollKeyFile = config.sops.secrets."users/${username}/crowdsec/crowdsec-capi-enrollment.key".path;
          configuration = {
            share_manual_decisions = true;
            share_tainted = true;
            share_custom = true;
            console_management = false;
            share_context = true;
          };
        };
      };
    };

    services.crowdsec-firewall-bouncer = {
      enable = true;
      registerBouncer.enable = true;
    };

    sops.secrets = {
      "users/${username}/crowdsec-capi-enrollment.key" = {
        group = "crowdsec";
        mode = "0440";
        sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      };
    };

    systemd.tmpfiles.rules = lib.optionals pangolin-traefik.enable [
      "d /var/log/traefik 0750 ${username} crowdsec -"
    ];
  };
}
