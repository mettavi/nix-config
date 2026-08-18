{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.crowdsec;
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
    # Shared log directory: Traefik (rootless podman, running as `username`)
    # writes here; CrowdSec (a separate system service) reads from here.
    # Kept outside the home directory so permissions aren't blocked by a
    # 0700 $HOME.
    systemd.tmpfiles.rules = [
      optionalString
      pangolin-traefik.enable
      "d /var/log/traefik 0750 ${username} crowdsec -"
    ];

    services.crowdsec = {
      enable = true;

      settings.general.api.server = {
        enable = true; # required — module fails without an explicit api client section
        listen_uri = "127.0.0.1:8080";
      };

      hub.collections = [
        optionalString
        pangolin-traefik.enable
        "crowdsecurity/traefik" # parsers + scenarios for Traefik access logs
        # Add more later, e.g. "crowdsecurity/http-cve"
      ];

      # configuration for a crowdsec security engine
      localConfig = {
        # list of data sources to be parsed
        acquisitions = [
          mkIf
          pangolin-traefik.enable
          {
            source = "file";
            filenames = [ "/var/log/traefik/access.log" ];
            labels.type = "traefik";
          }
        ];
      };
    };
    services.crowdsec-firewall-bouncer = {
      enable = true;

      # Auto-registers with the local `crowdsec` service and manages its own
      # API key — no manual `cscli bouncers add` step required.
      registerBouncer.enable = true;

      # `mode` defaults to "nftables" if networking.nftables.enable is true,
      # else "iptables" — leave unset unless you want to force one.
      # `api_url` defaults to the local LAPI (http://127.0.0.1:8080) automatically.
    };
  };
}
