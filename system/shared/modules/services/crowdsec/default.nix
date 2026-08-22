{
  config,
  hostname,
  lib,
  pkgs,
  secrets_path,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.crowdsec;
  pangolin-traefik = config.mettavi.system.services.pangolin;
in
{
  # See https://github.com/nixos/nixpkgs/issues/446764
  disabledModules = [ "services/security/crowdsec.nix" ];
  imports = [ ./crowdsec-patch.nix ];

  options.mettavi.system.services.crowdsec = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and set up the CrowdSec detection engine";
    };
  };

  config = mkIf cfg.enable {
    # Whitelist Parser Rule
    environment.etc."crowdsec/parsers/s02-enrich/my-whitelists.yaml".text = ''
      stage: s02-enrich
      name: my-ip-whitelists
      description: "Whitelist my home IP"
      whitelist:
        reason: "Admin home IP"
        ip:
          - "175.157.84.137"
        # cidr:
        #   - "175.157.84.0/24"
    '';

    systemd.tmpfiles.rules =
      let
        consoleSeed =
          (pkgs.formats.yaml { }).generate "console.yaml"
            config.services.crowdsec.settings.console.configuration;
      in
      optionals pangolin-traefik.enable [
        # Shared log directory: Traefik (rootless podman, running as `username`)
        # writes here; CrowdSec (a separate system service) reads from here.
        # Kept outside the home directory so permissions aren't blocked by a
        # 0700 $HOME.
        "d /var/log/traefik 0750 ${username} crowdsec -"
        # the file must exist before the module can write to it
        "f /var/lib/crowdsec/online_api_credentials.yaml 0750 crowdsec crowdsec - -"
        # the file must be recreated outside the nix store
        "C /var/lib/crowdsec/console.yaml 0750 crowdsec crowdsec - ${consoleSeed}"
      ];

    # NB: The crowdsec module is undergoing a refactor for nixos version 26.11
    # See https://github.com/NixOS/nixpkgs/pull/535319
    services.crowdsec = {
      enable = true;

      settings = {
        console = {
          tokenFile = config.sops.secrets."users/${username}/crowdsec-capi-enrollment.key".path;
          configuration = {
            share_manual_decisions = true;
            share_tainted = true;
            share_custom = true;
            console_management = false;
            share_context = true;
          };
        };
        general = {
          api.server = {
            enable = true; # required — module fails without an explicit api client section
            console_path = "/var/lib/crowdsec/console.yaml";
            listen_uri = "0.0.0.0:8085";
          };
        };
        lapi.credentialsFile = optionalString pangolin-traefik.enable "/var/lib/crowdsec/lapi-machine-credentials.yml";
        capi.credentialsFile = optionalString pangolin-traefik.enable "/var/lib/crowdsec/online_api_credentials.yaml";
      };

      hub.collections = [
        "crowdsecurity/linux" # baseline collection, always installed
      ]
      ++ lib.optionals pangolin-traefik.enable [
        "crowdsecurity/traefik" # parsers + scenarios for Traefik access logs
      ];
      # Add more later, e.g. "crowdsecurity/http-cve"

      # configuration for a crowdsec security engine
      localConfig = {
        # list of data sources to be parsed
        acquisitions = lib.optionals pangolin-traefik.enable [
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
      # `settings.api_url` defaults to the local crowdsec LAPI
      # (http://$\{config.services.crowdsec.settings.general.api.server.listen_uri}) automatically.
      # `settings.mode` defaults to "nftables" if networking.nftables.enable is true,
      # else "iptables" — leave unset unless you want to force one.
    };

    /*
      Claude.ai: "Three genuinely distinct bugs stacked on top of each other in your 26.05 nixpkgs:
      1. crowdsec-firewall-bouncer-register.service's StateDirectory includes "crowdsec",
         which triggers systemd's private-symlink migration of /var/lib/crowdsec — breaking crowdsec.service
         (plain ReadWritePaths, no StateDirectory) and any interactive cscli use.
         Fixed by mkForce-ing StateDirectory down to just the unit's own name,
         and restoring write access via ReadWritePaths = [ "/var/lib/crowdsec" ].
      2. The register script hardcodes the raw, unwrapped cscli binary instead of the wrapped one
         from crowdsec.nix that knows the config lives in the Nix store rather than /etc/crowdsec/config.yaml.
         Fixed with the corrected ExecStart.
      3. Missing After= ordering between the register and bouncer services, causing an intermittent boot-time race."
    */

    sops.secrets = {
      "users/${username}/crowdsec-capi-enrollment.key" = {
        group = "crowdsec";
        mode = "0440";
        sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      };
    };

    systemd.services.crowdsec-firewall-bouncer.serviceConfig.After = [
      "crowdsec-firewall-bouncer-register.service"
    ];

    systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
      # workaround: keeps the unit's own private state dir (for its api-key.cred file)
      # but drops crowdsec from the list, so it stops re-claiming and symlink-ifying /var/lib/crowdsec
      StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
      ReadWritePaths = [ "/var/lib/crowdsec" ];
      ExecStart = lib.mkForce (
        pkgs.writeShellScript "crowdsec-firewall-bouncer-register-start" ''
          set -e
          cscli=/run/current-system/sw/bin/cscli
          if $cscli bouncers list --output json | ${lib.getExe pkgs.jq} -e -- 'any(.[]; .name == "crowdsec-firewall-bouncer")' >/dev/null; then
            if [ ! -f /var/lib/crowdsec-firewall-bouncer-register/api-key.cred ]; then
              echo "Bouncer registered but API key is not present"
              exit 1
            fi
          else
            rm -f '/var/lib/crowdsec-firewall-bouncer-register/api-key.cred'
            if ! $cscli bouncers add --output raw -- crowdsec-firewall-bouncer >/var/lib/crowdsec-firewall-bouncer-register/api-key.cred; then
              rm /var/lib/crowdsec-firewall-bouncer-register/api-key.cred
              exit 1
            fi
          fi
        ''
      );
    };
  };
}
