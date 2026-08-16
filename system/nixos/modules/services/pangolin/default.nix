{
  config,
  hostname,
  inputs,
  lib,
  secrets_path,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.pangolin;
  hostSecrets.sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
in
{
  options.mettavi.system.services.pangolin = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and set up pangolin";
    };
  };

  config = mkIf cfg.enable {
    # to enable and configure generic podman settings
    mettavi.system.services.podman.enable = true;

    # Traffic boundaries for Controller and WireGuard Core
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    networking.firewall.allowedUDPPorts = [
      21820
      51820
    ];

    # enable lingering so that services stay up after logging out
    users.users."${username}" = {
      linger = true;
    };

    home-manager.users.${username} =
      let
        configHome = "${config.xdg.configHome}/containers/systemd/config";
      in
      {
        imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

        sops.secrets = {
          "users/${username}/crowdsec-lapi.key" = hostSecrets;
          "users/${username}/pangolin.env" = hostSecrets;
          "users/${username}/traefik.env" = hostSecrets;
        };

        virtualisation.quadlet = {
          containers = {
            pangolin = {
              autoStart = "default.target";
              containerConfig = {
                # "ee" is the enterprise edition (free for personal use)
                image = "docker.io/fosrl/pangolin:ee-latest";
                autoUpdate = "registry";
                environments = {
                  PANGOLIN_DOMAIN = "https://pangolin.mettavi.cloud";
                  DB_TYPE = "sqlite";
                };
                environmentFiles = [
                  config.sops.secrets."users/${username}/pangolin.env".path
                ];
                healthCmd = "curl -f http://localhost:3001/api/v1/";
                healthInterval = "10s";
                healthRetries = 15;
                healthTimeout = "10s";
                notify = "healthy";
                pod = "services.pod";
                volumes = [
                  "${configHome}:/app/config"
                  "${configHome}/letsencrypt:/app/config/letsencrypt:ro"
                ];
              };
              serviceConfig = {
                Restart = "always";
              };
            };
            gerbil = {
              autoStart = "default.target";
              containerConfig = {
                addCapabilities = [
                  "NET_ADMIN"
                  "SYS_MODULE"
                ];
                exec = [
                  "--reachableAt=http://localhost:3004"
                  "--generateAndSaveKeyTo=/var/config/key"
                  "--remoteConfig=http://localhost:3001/api/v1/"
                ];
                image = "docker.io/fosrl/gerbil:latest";
                pod = "services.pod";
                volumes = [
                  "${configHome}:/var/config"
                ];
              };
              serviceConfig = {
                Restart = "always";
              };
              unitConfig = {
                After = [ "pangolin.service" ];
                Requires = [ "pangolin.service" ];
              };
            };
            traefik = {
              autoStart = "default.target";
              containerConfig = {
                environmentFiles = [
                  config.sops.secrets."users/${username}/traefik.env".path
                ];
                exec = "--configFile=/etc/traefik/traefik_config.yml";
                image = "docker.io/traefik:latest";
                pod = "services.pod";
                volumes = [
                  "${configHome}/traefik:/etc/traefik:ro"
                  "${configHome}/letsencrypt:/letsencrypt"
                  "/var/log/traefik:/var/log/traefik"
                  "${
                    config.sops.secrets."users/${username}/crowdsec-lapi.key".path
                  }:/etc/traefik/crowdsec-lapi.key:ro"
                ];
              };
              serviceConfig = {
                Restart = "always";
              };
              unitConfig = {
                After = [ "pangolin.service" ];
                Requires = [ "pangolin.service" ];
              };
            };
          };
          pods = {
            services = {
              autoStart = "default.target";
              podConfig = {
                networks = [ "pasta" ];
                publishPorts = [
                  "80:80"
                  "443:443"
                  # uncomment if you enable HTTP/3 in Traefik
                  # "443:443/udp"
                  "21820:21820/udp"
                  "51820:51820/udp"
                ];
              };
              serviceConfig = {
                Restart = "always";
              };
              unitConfig = {
                Description = "Pangolin Pod";
                After = [ "network-online.target" ];
                Wants = [ "network-online.target" ];
              };
            };
          };
        };
        xdg.configFile = {
          # pangolin config file
          "containers/systemd/config/config.yml".text = # yaml
            ''
              # To see all available options, please visit the docs:
              # https://docs.pangolin.net/
              gerbil:
                start_port: 51820
                base_endpoint: "pangolin.mettavi.cloud"

              app:
                dashboard_url: "https://pangolin.mettavi.cloud"
                log_level: "info"
                telemetry:
                  anonymous_usage: true

              domains:
                domain1:
                  base_domain: "mettavi.cloud"
                  cert_resolver: "letsencrypt"

              email:
                smtp_host: "smtp.gmail.com"
                smtp_port: 587
                smtp_user: "${inputs.secrets.email.personal}"
                no_reply: "${inputs.secrets.email.personal}"

              server:
                cors:
                  origins: ["https://pangolin.mettavi.cloud"]
                  methods: ["GET", "POST", "PUT", "DELETE", "PATCH"]
                  allowed_headers: ["X-CSRF-Token", "Content-Type"]
                  credentials: false

              flags:
                require_email_verification: true
                disable_signup_without_invite: true
                disable_user_create_org: false
                allow_raw_resources: true 
            '';
        };
      };
  };
}
