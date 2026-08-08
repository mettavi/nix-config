{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.crowdsec;
in
{
  options.mettavi.system.services.crowdsec = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and set up the CrowdSec detection engine, watching Traefik access logs";
    };
  };

  config = mkIf cfg.enable {
    # Shared log directory: Traefik (rootless podman, running as `username`)
    # writes here; CrowdSec (a separate system service) reads from here.
    # Kept outside the home directory so permissions aren't blocked by a
    # 0700 $HOME.
    systemd.tmpfiles.rules = [
      "d /var/log/traefik 0750 ${username} crowdsec -"
    ];

    services.crowdsec = {
      enable = true;

      settings.general.api.server = {
        enable = true; # required — module fails without an explicit api client section
        listen_uri = "127.0.0.1:8080";
      };

      hub.collections = [
        "crowdsecurity/traefik" # parsers + scenarios for Traefik access logs
        # Add more later, e.g. "crowdsecurity/http-cve"
      ];

      localConfig.acquisitions = [
        {
          source = "file";
          filenames = [ "/var/log/traefik/access.log" ];
          labels.type = "traefik";
        }
      ];
    };
  };
}
