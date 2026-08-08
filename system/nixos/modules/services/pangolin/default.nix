{
  inputs,
  lib,
  secrets_path,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.pangolin;
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

        services.traefik = {
          enable = true;
          dataDir = "${config.users.users.${username}.home}/.config/containers/systemd/config/traefik";
          staticConfigOptions = {
            api = {
              dashboard = true;
              # Access the Traefik dashboard on <Traefik IP>:8080 of your server
              insecure = true;
            };
            certificatesResolvers.letsencrypt.acme = {
              caServer = "https://acme-v02.api.letsencrypt.org/directory";
              email = inputs.secrets.email.personal;
              storage = "/letsencrypt/acme.json";
              httpChallenge.entryPoint = "web";
            };
            entryPoints = {
              web = {
                address = ":80";
                # asDefault = true;
                # http.redirections.entrypoint = {
                #   to = "websecure";
                #   scheme = "https";
                # };
              };
              websecure = {
                address = ":443";
                # asDefault = true;
                http = {
                  encodedCharacters = {
                    allowEncodedQuestionMark = true;
                    allowEncodedSlash = true;
                  };
                  tls.certResolver = "letsencrypt";
                };
                # Uncomment to enable HTTP/3. You must also expose 443/udp in services.pod.
                # http3.advertisedPort = 443;
                transport.respondingTimeouts.readTimeout = "30m";
              };
            };
            experimental.plugins.badger = {
              moduleName = "github.com/fosrl/badger";
              version = "v1.4.0"; # Check github.com/fosrl/badger for the latest release.
            };
            log = {
              compress = true;
              level = "INFO";
              format = "common";
              maxAge = 3;
              maxBackups = 3;
              maxSize = 100;
            };
            ping.entryPoint = "web";
            providers = {
              file.filename = "/etc/traefik/dynamic_config.yml";
              http = {
                endpoint = "http://localhost:3001/api/v1/traefik-config";
                pollInterval = "5s";
              };
            };
            serversTransport.insecureSkipVerify = true;
          };
          dynamicConfigOptions = {
            http = {
              middlewares = {
                badger.plugin.badger.disableForwardAuth = true;
                redirect-to-https.redirectScheme.scheme = "https";
              };
              routers = {
                api-router = {
                  entryPoints = [ "websecure" ];
                  middlewares = [ "badger" ];
                  rule = "Host(`pangolin.mettavi.cloud`) && PathPrefix(`/api/v1`)";
                  service = "api-service";
                  tls.certResolver = "letsencrypt";
                };
                main-app-router-redirect = {
                  entryPoints = [ "web" ];
                  middlewares = [
                    "badger"
                    "redirect-to-https"
                  ];
                  rule = "Host(`pangolin.mettavi.cloud`)";
                  service = "next-service";
                };
                next-router = {
                  entryPoints = [ "websecure" ];
                  middlewares = [ "badger" ];
                  rule = "Host(`pangolin.mettavi.cloud`) && !PathPrefix(`/api/v1`)";
                  service = "next-service";
                  tls.certResolver = "letsencrypt";
                };
                ws-router = {
                  entryPoints = [ "websecure" ];
                  middlewares = [ "badger" ];
                  rule = "Host(`pangolin.mettavi.cloud`)";
                  service = "api-service";
                  tls.certResolver = "letsencrypt";
                };
              };
              services = {
                api-service.loadBalancer.servers.url = "http://localhost:3000";
                next-service.loadBalancer.servers.url = "http://localhost:3002";
              };
              tcp = {
                serversTransports = {
                  pp-transport-v1.proxyProtocol.version = 1;
                  pp-transport-v2.proxyProtocol.version = 2;
                };
              };
            };
          };
        };

        sops.secrets = {
          "users/${username}/pangolin.env" = {
            sopsFile = "${secrets_path}/secrets/hosts/remus.yaml";
          };
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
                exec = "--configFile=/etc/traefik/traefik_config.yml";
                image = "docker.io/traefik:latest";
                pod = "services.pod";
                volumes = [
                  "${configHome}/traefik:/etc/traefik:ro"
                  "${configHome}/letsencrypt:/letsencrypt"
                  "${configHome}/traefik/logs:/var/log/traefik"
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
          "${configHome}/config.yml".text = # yaml
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
