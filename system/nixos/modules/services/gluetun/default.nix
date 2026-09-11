{
  config,
  hostname,
  inputs,
  lib,
  nix_repo,
  pkgs,
  secrets_path,
  username,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.mettavi.system.services.gluetun;
  activeCfg = cfg.providers.${cfg.activeProvider};
  gluetunConfigDir = "${config.users.users.${username}.home}/.config/gluetun";
  mkContainer = config.mettavi.system.services.podman.mkContainer;
  patchedRefreshLoop =
    pkgs.runCommand "refresh-loop-patched.sh" { } # bash
      ''
        cp ${./refresh-loop-0_8_3.sh} $out
        chmod +w $out
        # do_docker_restart normally issues `docker restart` directly against the
        # podman socket, which conflicts with systemd's own supervision of the
        # quadlet-managed gluetun.service. Replace it with a pure signal file;
        # the actual restart is handled exclusively by systemd via the
        # gluetun-restart-trigger path-unit below.
        ${pkgs.gnused}/bin/sed -i \
          '/^do_docker_restart() {/,/^}/c\
          do_docker_restart() {\
          date -u +%Y-%m-%dT%H:%M:%SZ > /hostenv/restart-trigger\
          log info "Signaled systemd to restart $GLUETUN_CONTAINER"\
          }' $out
        chmod +x $out
      '';
  pfEnvDir = "/var/lib/gluetun-portforward";
  pfEnvFile = "${pfEnvDir}/server-names.env";
in
{
  options.mettavi.system.services.gluetun = {
    enable = mkEnableOption "Install and set up the Gluetun VPN service";
    activeProvider = mkOption {
      type = str;
      default = "custom-pia";
      description = "Which entry in `providers` to actually run";
    };
    providers = mkOption {
      type = attrsOf (submodule {
        options = {
          name = mkOption {
            type = enum [
              "custom"
              "private internet access"
            ];
            default = "custom";
            description = "Specify a Gluetun supported VPN provider to use";
          };
          type = mkOption {
            type = enum [
              "openvpn"
              "wireguard"
            ];
            default = "wireguard";
            description = "Whether to connect using the OpenVPN or Wireguard VPN protocol";
          };
          servers = {
            categories = mkOption {
              type = str;
              default = "";
              description = "Comma separated list of server categories";
            };
            cities = mkOption {
              type = str;
              default = "";
              description = "Comma separated list of cities";
            };
            countries = mkOption {
              type = str;
              default = "";
              description = "Comma separated list of countries";
            };
            # Beware this is the narrowest filter
            hostnames = mkOption {
              type = str;
              default = "";
              description = "Comma separated list of server hostnames";
            };
            # sets SERVER_NAMES which is REQUIRED for PIA port-forwarding with wireguard
            # unless using the pia-wg-refresh tool
            names = mkOption {
              type = str;
              default = "";
              description = "Comma separated list of server names";
            };
            names-pf = mkOption {
              type = str;
              default = "";
              description = "Comma separated list of server names supporting port-forwarding";
            };
            regions = mkOption {
              type = str;
              default = "";
              description = "Comma separated list of VPN regions (eg. Australia)";
            };
          };
          openvpn = {
            user = mkOption {
              type = str;
              default = "";
              description = "The username for the OpenVPN provider";
            };
            password = mkOption {
              type = str;
              default = "";
              description = "The password for the OpenVPN provider";
            };
            customConfig = mkOption {
              type = path;
              default = "";
              description = "Custom OpenVPN server endpoint port";
            };
            endpointPort = mkOption {
              type = types.str;
              default = "";
              description = "Custom OpenVPN server endpoint port";
            };
            protocol = mkOption {
              type = enum [
                "upd"
                "tcp"
              ];
              default = "udp";
              description = "Network protocol to use, only valid for OpenVPN";
            };
          };
          portForwarding = {
            enabled = mkOption {
              type = str;
              default = "on";
              description = "Whether to turn port forwarding on";
            };
            only = mkOption {
              type = str;
              # not applicable to the "custom" provider type
              default = "false";
              description = "Whether to only select servers with port forwarding";
            };
            provider = mkOption {
              type = str;
              default = "private internet access";
              description = "The provider of the port forwarding service";
            };
          };
          # Use this command to get a list of PIA servers that support port-forwarding:
          # curl -s "https://serverlist.piaservers.net/vpninfo/servers/v6" \
          # | jq -r '.regions[] | select(.port_forward == true) | .id' | sort -u
          private-internet-access = {
            useWgRefresh = mkOption {
              type = bool;
              default = true;
              description = "Whether to automatically update the wireguard config file with the pia-wg-refresh tool";
            };
            piaRegion = mkOption {
              type = str;
              default = "uk";
              description = "PIA region code for pia-wg-refresh (e.g. us_chicago)";
            };
          };
          wireguard = {
            addresses = mkOption {
              type = str;
              default = "";
              description = "The client network interface address in the format xx.xx.xx.xx/xx";
            };
            allowedIPs = mkOption {
              type = str;
              default = "0.0.0.0/0";
              description = "Wireguard peer allowed ips";
            };
            endpointIP = mkOption {
              type = types.str;
              default = "";
              description = "Custom wireguard server endpoint IP address (not hostname)";
            };
            endpointPort = mkOption {
              type = types.str;
              default = "";
              description = "Custom wireguard server endpoint port";
            };
            implementation = mkOption {
              type = types.enum [
                "auto"
                "kernelspace"
                "userspace"
              ];
              default = "auto";
              description = "Wireguard implementation to use";
            };
            presharedKey = mkOption {
              type = str;
              default = "";
              description = "Wireguard pre-shared key";
            };
            publicKey = mkOption {
              type = str;
              default = "";
              description = "Wireguard server public key to use.";
            };
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    # to enable and configure generic podman settings
    mettavi.system.services.podman.enable = true;

    # this option is not required as we mount the podman socket directly (see the volume mounts below)
    # virtualisation.podman.dockerSocket.enable = true;

    ######### PROVIDER CONFIGURATION ##############
    # Set the key name and non-default values for each attribute set
    # this set currently inherits the options defaults
    mettavi.system.services.gluetun = {
      activeProvider = "custom-pia";
      providers = {
        "custom-pia" = { config, ... }: {
          # sets SERVER_NAMES which is REQUIRED for PIA port-forwarding with wireguard
          # unless using the pia-wg-refresh tool
          servers.names = if config.private-internet-access.useWgRefresh then "" else "Server-10872-2a";
        };
        "pia-ovpn" = {
          name = "private internet access";
          type = "openvpn";
          portForwarding = {
            enabled = "on";
            only = "true";
          };
        };
      };
    };

    environment.shellAliases = {
      pia-cfg = getExe pkgs.linpkgs.pia-wg-config;
      pia-cfg2 = getExe pkgs.linpkgs.pia-wg-config2;
    };

    environment.systemPackages = with pkgs.linpkgs; [
      pia-wg-config
      pia-wg-config2
    ];

    sops.secrets =
      let
        gluetunSecrets.sopsFile = "${secrets_path}/secrets/apps/gluetun.yaml";
      in
      mkMerge [
        {
          "users/${username}/gluetun-${cfg.activeProvider}.env" = gluetunSecrets;
          "users/${username}/qbittorrent-${hostname}.env" = gluetunSecrets;
        }
        (mkIf (cfg.activeProvider == "custom-pia") {
          "users/${username}/wg-refresh-${cfg.activeProvider}.env" = gluetunSecrets;
        })
      ];

    # creates the port forwarding .env file
    system.activationScripts.gluetun-portforward-env = ''
      mkdir -p ${pfEnvDir}
      [ -f ${pfEnvFile} ] || echo "SERVER_NAMES=" > ${pfEnvFile}
    '';

    # creates the file containing the auth code for the access
    # to the two Glueton API endpoints needed by pia-wg-refresh
    systemd.services.gluetun-auth-config =
      let
        authConfigFile = (pkgs.formats.toml { }).generate "gluetun-auth-config.toml" {
          roles = [
            {
              name = "pia-wg-refresh";
              routes = [
                "GET /v1/publicip/ip"
                "GET /v1/portforward"
              ];
              auth = "none";
            }
          ];
        };
      in
      {
        after = [ "sops-nix.service" ];
        before = [ "gluetun.service" ];
        wantedBy = [ "gluetun.service" ];
        serviceConfig.Type = "oneshot";
        script = ''
          install -Dm0644 ${authConfigFile} ${gluetunConfigDir}/auth/config.toml
        '';
      };

    systemd.paths.gluetun-restart-trigger = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathModified = "${pfEnvDir}/restart-trigger";
    };
    systemd.services.gluetun-restart-trigger = {
      serviceConfig.Type = "oneshot";
      script = "systemctl restart gluetun.service";
    };

    # host-side: watch the file, restart gluetun.service when it changes
    systemd.paths.gluetun-server-names-sync = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathModified = pfEnvFile;
    };

    systemd.services.gluetun-server-names-sync = {
      serviceConfig.Type = "oneshot";
      script = "systemctl restart gluetun.service";
    };

    # prevent services from automtically starting when running `nixos-rebuild switch`
    systemd.services = {
      gluetun = {
        restartIfChanged = false;
      };
      qbittorrent-port-forward = {
        restartIfChanged = false;
      };
    };

    # create necessary directories, these are not auto-created by containers
    systemd.tmpfiles.rules = [
      "d ${gluetunConfigDir}/wireguard 0750 ${username} users -"
      "d ${config.users.users.${username}.home}/.config/vuetorrent-backend 0750 ${username} users -"
      "d /var/log/pia-wg-refresh 0750 root root -"
    ];

    virtualisation.quadlet = {
      containers = {
        gluetun = mkContainer {
          autoStart = false;
          containerConfig = {
            addCapabilities = [
              "NET_ADMIN"
              "NET_RAW"
            ];
            # this is the name that the `pia-wg-refresh` will look for
            name = "gluetun";
            devices = [ "/dev/net/tun:/dev/net/tun" ];
            environments = {
              # GENERAL
              VPN_SERVICE_PROVIDER = activeCfg.name;
              VPN_TYPE = activeCfg.type;
              LOG_LEVEL = "DEBUG";
              UPDATER_PERIOD = "480h";
              SERVER_REGIONS = activeCfg.servers.regions;

              # WIREGUARD
              WIREGUARD_IMPLEMENTATION = activeCfg.wireguard.implementation;
              WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL = "25s";

              # PORT FORWARDING
              VPN_PORT_FORWARDING = activeCfg.portForwarding.enabled;
              PORT_FORWARD_ONLY = activeCfg.portForwarding.only;
              VPN_PORT_FORWARDING_PROVIDER = activeCfg.portForwarding.provider;
            }
            # don't read these variables if they are provided by a mounted wireguard config file (eg. wg0.conf)
            // (filterAttrs (_: v: v != null && v != "") {
              SERVER_NAMES = activeCfg.servers.names; # configured automatically if using pia-wg-refresh
              WIREGUARD_ADDRESSES = activeCfg.wireguard.addresses;
              WIREGUARD_ALLOWED_IPS = activeCfg.wireguard.allowedIPs;
              WIREGUARD_ENDPOINT_IP = activeCfg.wireguard.endpointIP;
              WIREGUARD_ENDPOINT_PORT = activeCfg.wireguard.endpointPort;
              WIREGUARD_PUBLIC_KEY = activeCfg.wireguard.publicKey;
            });
            environmentFiles = [
              # gluetun reads its SERVER_NAMES from this file at every (re)start
              pfEnvFile
              "${config.sops.secrets."users/${username}/gluetun-${cfg.activeProvider}.env".path}"
            ];
            healthCmd = "CMD-SHELL /gluetun-entrypoint healthcheck";
            healthInterval = "30s";
            healthOnFailure = "kill";
            healthRetries = 3;
            healthStartPeriod = "20s";
            healthTimeout = "10s";
            image = "docker.io/qmcgaw/gluetun:v3.41.3";
            notify = "healthy";
            podmanArgs = [
              # The leading colon tells Alpine to read the symlink configuration live,
              # and since we already pass it as a Volume mount via 'mkContainer',
              # Gluetun parses it perfectly without breaking sandbox protocols
              "--env=TZ=:/etc/localtime"
            ];
            publishPorts = [
              # qBittorrent ports, vuetorrent-backend will forward requests to it so no need to expose it
              # "8090:8090/tcp" # qBittorrent WEBUI_PORT

              # vuetorrent-backend
              "8091:8091"
            ];
            volumes = [
              # bind mounts
              "${gluetunConfigDir}:/gluetun"
              "${gluetunConfigDir}/wireguard/wg0.conf:/gluetun/wireguard/wg0.conf:ro"
              "${gluetunConfigDir}/auth:/gluetun/auth"
            ];
          };
          serviceConfig = {
            RestartSec = "10";
            Restart = "on-failure";
          };
          unitConfig = {
            # start the dependent service on launch
            Wants = [ "pia-wg-refresh.service" ];
          };
        };
        pia-wg-refresh =
          let
            # the alpine container does not have bash and cannot resolve nix store paths - so use "writeScript" here
            updateServerNameScript =
              pkgs.writeScript "update-server-name.sh" # sh
                ''
                  #!/bin/sh
                  set -eu

                  file="/hostenv/server-names.env"
                  new="SERVER_NAMES=$PIA_SERVER_NAME"

                  if [ -f "$file" ] && [ "$(cat "$file")" = "$new" ]; then
                      exit 0
                    fi

                     tmp="''${file}.tmp.$$"
                     printf '%s\n' "$new" > "$tmp"
                     mv "$tmp" "$file"
                '';
          in
          mkContainer {
            autoStart = false;
            containerConfig = {
              name = "pia-wg-refresh";
              image = "ghcr.io/ccarpinteri/pia-wg-refresh:v0.8.3";
              environments = {
                CHECK_INTERVAL_SECONDS = "60";
                HEALTHY_CHECK_INTERVAL_SECONDS = "1800";
                FAIL_THRESHOLD = "5";
                MAX_GENERATION_RETRIES = "3";
                GLUETUN_CONTAINER = "gluetun";
                LOG_LEVEL = "debug";
                # pia-wg-refresh writes to SERVER_NAMES (bind-mounted read-write) whenever the port/server changes
                ON_PORT_CHANGE_SCRIPT = "/hooks/update-server-name.sh";
                PIA_PORT_FORWARDING = if (activeCfg.portForwarding.enabled == "on") then "true" else "false";
                PIA_REGION = activeCfg.private-internet-access.piaRegion;
                WG_CONF_PATH = "/config/wg0.conf";
              };
              environmentFiles = optionals (cfg.activeProvider == "custom-pia") [
                config.sops.secrets."users/${username}/wg-refresh-${cfg.activeProvider}.env".path
              ];
              healthCmd = "grep -q \"^Endpoint\" /config/wg0.conf || exit 1";
              healthInterval = "5s";
              healthStartPeriod = "10s";
              volumes = [
                "${patchedRefreshLoop}:/app/refresh-loop.sh:ro"
                "${pfEnvDir}:/hostenv"
                "${updateServerNameScript}:/hooks/update-server-name.sh:ro"
                "${config.users.users.${username}.home}/.config/gluetun/wireguard:/config"
                "/run/podman/podman.sock:/var/run/docker.sock"
                "/var/log/pia-wg-refresh:/logs"
              ];
            };
            serviceConfig = {
              Restart = "on-failure";
              RestartSec = "10";
            };
            unitConfig = {
              After = [ "gluetun.service" ];
            };
          };

        # see the wiki at https://github.com/qbittorrent/qBittorrent/wiki
        qbittorrent =
          let
            qbtContainerConfDir = "${config.users.users.${username}.home}/.config/qbittorrent-container";
            qbtPinnedSettingsFile = (pkgs.formats.ini { }).generate "qbittorrent-pinned.ini" {
              Preferences = {
                "WebUI\\HostHeaderValidation" = false; # required for vuetorrent-backend
                "WebUI\\LocalHostAuth" = false; # required for gluetun
              };
              BitTorrent = {
                "Session\\DefaultSavePath" = "/downloads/completed";
                # these two settings recommended in the docs,
                # see https://github.com/qdm12/gluetun-wiki/blob/main/setup/popular-apps.md
                # and https://github.com/passteque/gluetun/issues/2735
                "Session\\Interface" = "tun0";
                "Session\\InterfaceAddress" = "0.0.0.0";
                "Session\\TempPath" = "/downloads/incomplete";
                "Session\\TempPathEnabled" = true;
              };
            };
          in
          mkContainer {
            autoStart = false;
            containerConfig = {
              image = "docker.io/linuxserver/qbittorrent:5.2.3";
              networks = [ "container:gluetun" ]; # joins gluetun's netns — no ports of its own
              environments = {
                PUID = toString config.users.users.${username}.uid;
                PGID = toString config.users.groups.users.gid;
                # NB: The TORRENTING_PORT value is managed separately
                WEBUI_PORT = "8090";
              };
              volumes = [
                "${config.users.users.${username}.home}/Downloads/qbittorrent:/downloads"
                "${qbtContainerConfDir}:/config"
              ];
            };
            serviceConfig = {
              ExecStartPre = pkgs.writeShellScript "pin-qbittorrent-settings" ''
                targetDir="${qbtContainerConfDir}/qBittorrent"
                conf="$targetDir/qBittorrent.conf"
                secretFile="${config.sops.secrets."users/${username}/qbittorrent-${hostname}.env".path}"

                # Ensure the directory exists on the host
                ${pkgs.coreutils}/bin/mkdir -p "$targetDir"

                # Initialize an empty file if it doesn't exist yet
                [ -f "$conf" ] || touch "$conf"

                # 1. Merge static pinned settings
                # Merge pinned Nix settings into the untracked host config
                ${pkgs.crudini}/bin/crudini --merge "$conf" < ${qbtPinnedSettingsFile}

                # 2. Inject secret password hash from SOPS
                if [ -f "$secretFile" ]; then
                  set -a
                  . "$secretFile"
                  set +a

                  if [ -n "''${QBT_PASSWORD_HASH:-}" ]; then
                    ${pkgs.crudini}/bin/crudini --set "$conf" Preferences 'WebUI\Username' '${inputs.secrets.username.primary}'
                    ${pkgs.crudini}/bin/crudini --set "$conf" Preferences 'WebUI\Password_PBKDF2' "$QBT_PASSWORD_HASH"
                  fi
                fi
              '';
              Restart = "on-failure";
              RestartSec = "10";
            };
            unitConfig = {
              After = [
                "home-manager-${username}.service"
                "gluetun.service"
              ];
              # tell gluetun to stop this container first before shutting down
              Requires = [
                "gluetun.service"
              ];
            };
          }
          // optionalAttrs (activeCfg.portForwarding.enabled == "on") {
            qbittorrent-port-forward = mkContainer {
              containerConfig = {
                name = "qbittorrent-port-forward";
                image = "docker.io/mjmeli/qbittorrent-port-forward-gluetun-server:2025.12.21.02";
                networks = [ "container:gluetun" ]; # same netns as gluetun + qbittorrent
                environments = {
                  QBT_ADDR = "http://localhost:8090"; # matches your WEBUI_PORT
                  GTN_ADDR = "http://localhost:8000"; # gluetun's default control server port
                };
                environmentFiles = [
                  config.sops.secrets."users/${username}/qbittorrent-${hostname}".path
                ];
              };
              serviceConfig = {
                Restart = "on-failure";
                RestartSec = "10";
              };
              unitConfig = {
                After = [
                  "gluetun.service"
                  "qbittorrent.service"
                ];
                Requires = [
                  "gluetun.service"
                  "qbittorrent.service"
                ];
              };
            };
          };
        # See https://github.com/VueTorrent/vuetorrent-backend/blob/main/docker-compose.gluetun.yml
        vuetorrent-backend = {
          containerConfig = {
            name = "vuetorrent-backend";
            environments =
              let
                qbitWebPort =
                  config.virtualisation.quadlet.containers.qbittorrent.containerConfig.environments.WEBUI_PORT;
              in
              {
                # Backend port can't match qbit one because of the network_mode
                # You'll have to remove "Host header validation" in qbit settings > WebUI
                PORT = "8091";
                # Here we can use localhost because both qbit and backend container are on the same docker host ("container:gluetun")
                QBIT_BASE = "http://localhost:${qbitWebPort}";
                # Use "dev" for nightly releases
                RELEASE_TYPE = "stable";
                # Optional, refer to the node-schedule package for compatible syntax
                # UPDATE_VT_CRON = "0 * * * *";

                # Define this if using self-signed certificates on qBittorrent
                # - NODE_EXTRA_CA_CERTS=/config/ssl/cert.pem
                # You can also disable SSL verification (not recommended)
                # - USE_INSECURE_SSL=true

                # Only enable if backend container is behind a proxy server which already add x-forward headers
                # - SKIP_X_FORWARD_HEADERS=true
                # Create a Github PAT with your account to increase API rate limit, fine-grained with only public repo access is enough
                # - GITHUB_AUTH=${GITHUB_AUTH}

                # Log all received requests
                # - LOG_REQUESTS=true

                # If you want HTTPS, define the following variables with respective paths
                # - SSL_CERT_PATH=/config/ssl/cert.pem
                # - SSL_KEY_PATH=/config/ssl/key.pem
                # Use these instead for passing the value directly
                # - SSL_CERT=*****
                # - SSL_KEY=*****
              };
            image = "ghcr.io/vuetorrent/vuetorrent-backend:2.7.3";
            networks = [ "container:gluetun" ]; # joins gluetun's netns — no ports of its own
            volumes = [
              "${config.users.users.${username}.home}/.config/vuetorrent-backend:/config"
            ];
          };
          serviceConfig = {
            Restart = "on-failure";
          };
          unitConfig = {
            After = [
              "gluetun.service"
              "qbittorrent.service"
            ];
            # tell gluetun to stop this container first before shutting down
            Requires = [ "gluetun.service" ];
          };
        };
      };
    };
    home-manager.users.${username} =
      { config, ... }:
      let
        inherit (config.lib.file) mkOutOfStoreSymlink;
      in
      {
        xdg.configFile = {
          # link without copying to nix store (manage externally) - must use absolute paths
          # NB: apps that atomically write their own config commonly overwrite file
          # symlinks outright, so symlink the parent directory instead
          "vuetorrent-backend" = {
            source = mkOutOfStoreSymlink "${config.home.homeDirectory}/${nix_repo}/system/nixos/modules/services/gluetun/vuetorrent-backend";
          };
        };
      };
  };
}
