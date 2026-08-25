{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
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
      443 # for HTTP/3
      21820
      51820
    ];

    # create directories required by pangolin
    systemd.tmpfiles.rules =
      let
        pangolinConfigHome = "${config.users.users.${username}.home}/.config/containers/systemd/config";
      in
      [
        # type path mode user group (expiry) (argument)
        "d ${pangolinConfigHome}/db 0755 ${username} users -"
        "d ${pangolinConfigHome}/letsencrypt 0755 ${username} users -"
        "f ${pangolinConfigHome}/letsencrypt/acme.json 0600 ${username} users - {}"
        "d ${pangolinConfigHome}/traefik/logs 0755 ${username} users -"
        "z /var/lib/GeoIP 0755 - - -"
        "Z /var/lib/GeoIP/*.mmdb 0644 - - -"
      ];

    # enable lingering so that services stay up after logging out
    users.users."${username}" = {
      linger = true;
    };

    home-manager.users.${username} =
      {
        config,
        lib,
        nixosConfig,
        ...
      }:
      let
        configHome = "${config.xdg.configHome}/containers/systemd/config";
        crowdsec = nixosConfig.mettavi.system.services.crowdsec;
        geoIPUpdate = nixosConfig.mettavi.system.services.geoipupdate;
        pangolinConfigAttrs = {
          app = {
            dashboard_url = "https://pangolin.mettavi.cloud";
            log_level = "info";
            telemetry = {
              anonymous_usage = true;
            };
          };
          domains = {
            domain1 = {
              base_domain = "mettavi.cloud";
              cert_resolver = "cloudflare";
              prefer_wildcard_cert = true;
            };
          };
          email = {
            smtp_host = "9wmsrvh2zzw2.jd2m.mail-manager-smtp.amazonaws.com";
            smtp_port = 587;
            smtp_secure = true;
            no_reply = inputs.secrets.email.cloud;
          };
          gerbil = {
            start_port = 51820;
            base_endpoint = "pangolin.mettavi.cloud";
          };
          server = {
            cors = {
              origins = [ "https://pangolin.mettavi.cloud" ];
              methods = [
                "GET"
                "POST"
                "PUT"
                "DELETE"
                "PATCH"
              ];
              allowed_headers = [
                "X-CSRF-Token"
                "Content-Type"
              ];
              credentials = false;
            };
            integration_port = 3003;
            maxmind_db_path = if geoIPUpdate.enable then "/var/lib/GeoIP/GeoLite2-Country.mmdb" else "";
          };
          flags = {
            # provides programmatic access to Pangolin functionality
            enable_integration_api = true;
            require_email_verification = true;
            # this is required for the initial admin setup
            disable_signup_without_invite = true;
            disable_user_create_org = false;
            allow_raw_resources = true;
          };
        };

        traefikStaticConfigAttrs = {
          api = {
            dashboard = true;
            # Access the Traefik dashboard on <Traefik IP>:8080 of your server
            insecure = true;
          };
          certificatesResolvers = {
            cloudflare = {
              acme = {
                caServer = "https://acme-v02.api.letsencrypt.org/directory";
                email = inputs.secrets.email.personal;
                storage = "/letsencrypt/acme.json";
                # required for wildcard certs, see https://docs.pangolin.net/self-host/advanced/wild-card-domains
                dnsChallenge = {
                  provider = "cloudflare";
                  delayBeforeCheck = "60s";
                  # prevent Traefik from trying to query DNS resolvers, avoiding local timeouts
                  disablePropagationCheck = true;
                  resolvers = [
                    "1.1.1.1:53"
                    "1.0.0.1:53"
                  ];
                };
              };
            };
          };
          entryPoints = {
            web = {
              address = ":80";
              http = {
                redirections = {
                  entrypoint = {
                    to = "websecure";
                    scheme = "https";
                  };
                };
              };
            };
            websecure = {
              address = ":443";
              http = {
                encodedCharacters = {
                  allowEncodedQuestionMark = true;
                  allowEncodedSlash = true;
                };
                tls = {
                  certResolver = "cloudflare";
                };
              };
              # Uncomment to enable HTTP/3. You must also expose 443/udp in services.pod.
              http3 = {
                advertisedPort = 443;
              };
              transport = {
                respondingTimeouts = {
                  readTimeout = "30m";
                };
              };
            };
          };
          # includes local plugins that can be used without publishing them to the Traefik plugin catalog
          experimental = {
            plugins = {
              badger = {
                moduleName = "github.com/fosrl/badger";
                version = "v1.4.0";
              };
            }
            // lib.optionalAttrs crowdsec.enable {
              bouncer = {
                moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
                version = "v1.7.1";
              };
            };
          };
          # log for analyzing traffic and debugging requests
          accessLog = {
            filePath = "/var/log/traefik/access.log";
            format = "json";
          };
          # log for monitoring the proxy's operation
          log = {
            compress = true;
            level = "INFO";
            format = "common";
            maxAge = 3;
            maxBackups = 3;
            maxSize = 100;
          };

          ping = {
            entryPoint = "web";
          };
          providers = {
            file = {
              filename = "/etc/traefik/dynamic_config.yml";
            };
            http = {
              endpoint = "http://localhost:3001/api/v1/traefik-config";
              pollInterval = "5s";
            };
          };
          serversTransport = {
            insecureSkipVerify = true;
          };
        };

        traefikDynamicConfigAttrs = {
          http = {
            middlewares = {
              badger = {
                plugin = {
                  badger = {
                    disableForwardAuth = true;
                  };
                };
              };
            }
            // lib.optionalAttrs crowdsec.enable {
              crowdsec = {
                plugin = {
                  bouncer = {
                    enabled = true;
                    # recommended: syncs the ban list every 60s, fastest per-request path
                    crowdsecMode = "stream";
                    crowdsecLapiScheme = "http";
                    # reaches the host via pasta's loopback passthrough
                    # crowdsecLapiHost = "127.0.0.1:8085";
                    crowdsecLapiHost = "host.containers.internal:8085";
                    crowdsecLapiKeyFile = "/etc/traefik/traefik-bouncer.key";
                  };
                };
              };
            };
            routers = {
              api-router = {
                entryPoints = [ "websecure" ];
                middlewares =
                  if crowdsec.enable then
                    [
                      "badger"
                      "crowdsec"
                    ]
                  else
                    [ "badger" ];
                rule = "Host(`pangolin.mettavi.cloud`) && PathPrefix(`/api/v1`)";
                service = "api-service";
                tls = {
                  certResolver = "cloudflare";
                };
              };
              int-api-router = {
                entryPoints = [ "websecure" ];
                middlewares =
                  if crowdsec.enable then
                    [
                      "badger"
                      "crowdsec"
                    ]
                  else
                    [ "badger" ];
                rule = "Host(`api.mettavi.cloud`)";
                service = "int-api-service";
                tls = {
                  certResolver = "cloudflare";
                };
              };
              next-router = {
                entryPoints = [ "websecure" ];
                middlewares =
                  if crowdsec.enable then
                    [
                      "badger"
                      "crowdsec"
                    ]
                  else
                    [ "badger" ];
                rule = "Host(`pangolin.mettavi.cloud`) && !PathPrefix(`/api/v1`)";
                service = "next-service";
                tls = {
                  certResolver = "cloudflare";
                  domains = [
                    {
                      main = "mettavi.cloud";
                      sans = [ "*.mettavi.cloud" ];
                    }
                  ];
                };
              };
              ws-router = {
                entryPoints = [ "websecure" ];
                middlewares =
                  if crowdsec.enable then
                    [
                      "badger"
                      "crowdsec"
                    ]
                  else
                    [ "badger" ];
                rule = "Host(`pangolin.mettavi.cloud`)";
                service = "api-service";
                tls = {
                  certResolver = "cloudflare";
                };
              };
            };
            services = {
              # the REST API
              api-service = {
                loadBalancer = {
                  servers = [
                    { url = "http://localhost:3000"; }
                  ];
                };
              };
              # the integration API
              int-api-service = {
                loadBalancer = {
                  servers = [
                    # localhost, not "pangolin:3003" — matches your existing services, since containers share the pod's network namespace
                    { url = "http://localhost:3003"; }
                  ];
                };
              };
              # the pangolin web interface (written in next js)
              next-service = {
                loadBalancer = {
                  servers = [
                    { url = "http://localhost:3002"; }
                  ];
                };
              };
            };
            # if the tcp is not being used, the config below will cause an error
            # tcp = {
            #   serversTransports = {
            #     pp-transport-v1 = {
            #       proxyProtocol = {
            #         version = 1;
            #       };
            #     };
            #     pp-transport-v2 = {
            #       proxyProtocol = {
            #         version = 2;
            #       };
            #     };
            #   };
            # };
          };
        };
      in
      {
        imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

        # config.yml is now written by home.activation.pangolinConfig below,
        # NOT declared here — quadlet bind-mounts preserve symlinks, and a
        # /nix/store symlink is unreadable inside the container's mount namespace.
        home.activation.pangolinConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          install -m644 ${
            (pkgs.formats.yaml { }).generate "pangolin-config.yml" pangolinConfigAttrs
          } "${configHome}/config.yml"
        '';

        home.activation.traefikStaticConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          install -m644 ${
            (pkgs.formats.yaml { }).generate "traefik_config.yml" traefikStaticConfigAttrs
          } "${configHome}/traefik/traefik_config.yml"
        '';

        home.activation.traefikDynamicConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          install -m644 ${
            (pkgs.formats.yaml { }).generate "dynamic_config.yml" traefikDynamicConfigAttrs
          } "${configHome}/traefik/dynamic_config.yml"
        '';

        sops.secrets = {
          # generate with `crowdsec cscli bouncers add myBouncerName`
          "users/${username}/traefik-bouncer.key" = hostSecrets;
          "users/${username}/pangolin.env" = hostSecrets;
          "users/${username}/traefik.env" = hostSecrets;
        };

        virtualisation.quadlet = {
          containers = {
            pangolin = {
              autoStart = "default.target";
              containerConfig = {
                # "ee" is the enterprise edition (free for personal use)
                image = "docker.io/fosrl/pangolin:ee-1.21.1";
                # use the renovate GitHub workflow to check for version updates
                # autoUpdate = "registry";
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
                  "/var/lib/GeoIP:/var/lib/GeoIP:ro"
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
                  # NB: do not use a symlink (path=... in sops) because the container cannot see the nix store
                  "${
                    config.sops.secrets."users/${username}/traefik-bouncer.key".path
                  }:/etc/traefik/traefik-bouncer.key:ro"
                ];
              };
              serviceConfig = {
                Restart = "always";
              };
              unitConfig = {
                After = [
                  "pangolin.service"
                ];
                Requires = [
                  "pangolin.service"
                ];
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
                  "443:443/udp"
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
      };
  };
}
