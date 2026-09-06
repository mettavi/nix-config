{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.mettavi.system.services.gluetun;
  activeCfg = cfg.providers.${cfg.activeProvider};
  # creates the two read-only Gluetun control server API endpoints pia-wg-refresh needs access to
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
  gluetunConfigDir = "${config.users.users.${username}.home}/.config/gluetun";
  pfEnvDir = "/var/lib/gluetun-portforward";
  pfEnvFile = "${pfEnvDir}/server-names.env";
  sopsGluetunFile = "${secrets_path}/secrets/apps/gluetun.yaml";
  updateServerNameScript = pkgs.writeShellScript "update-server-name.sh" ''
    echo "SERVER_NAMES=$PIA_SERVER_NAME" > /hostenv/server-names.env
  '';
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
            # required for PIA port-forwarding with wireguard
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
            piaRegion = mkOption {
              type = str;
              default = "";
              description = "PIA region code for pia-wg-refresh (e.g. us_chicago)";
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
              description = "The password for the OpenVPN provider";
            };
          };
          portForwarding = {
            enabled = mkOption {
              type = str;
              default = "on";
              desription = "Whether to turn port forwarding on";
            };
            only = mkOption {
              type = str;
              default = "true";
              description = "Whether to only select servers with port forwarding";
            };
            provider = mkOption {
              type = str;
              default = "private internet access";
              description = "The provider of the port forwarding service";
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
              default = "0.0.0.0/0,::/0";
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

    environment.shellAliases = {
      pia-cfg = getExe pkgs.linpkgs.pia-wg-config;
      pia-cfg2 = getExe pkgs.linpkgs.pia-wg-config2;
    };

    environment.systemPackages = with pkgs.linpkgs; [
      pia-wg-config
      pia-wg-config2
    ];

    sops.secrets = {
      "users/${username}/gluetun-${cfg.activeProvider}.env" = sopsGluetunFile;
      "users/${username}/wg-refresh-${cfg.activeProvider}.env" = sopsGluetunFile;
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

    systemd.tmpfiles.rules = [
      # creates the file containing the auth code for the access
      # to the two Glueton API endpoints needed by pia-wg-refresh
      "d ${gluetunConfigDir}/auth 0750 ${username} users -"
      "L+ ${gluetunConfigDir}/auth/config.toml - - - - ${authConfigFile}"
      # creates the port forwarding .env file
      "d ${pfEnvDir} 0750 root root -"
      "f ${pfEnvFile} 0640 root root - SERVER_NAMES="
    ];

    virtualisation.quadlet = {
      containers = {
        gluetun = {
          autoStart = false;
          containerConfig = {
            addCapabilities = [
              "NET_ADMIN"
              "NET_RAW"
            ];
            # this is the name that the `pia-wg-refresh` will look for
            containerName = "gluetun";
            devices = [ "/dev/net/tun:/dev/net/tun" ];
            environments = {
              # GENERAL
              VPN_SERVICE_PROVIDER = cfg.activeProvider;
              VPN_TYPE = activeCfg.type;
              LOG_LEVEL = "INFO";
              UPDATER_PERIOD = "480h";
              SERVICE_REGIONS = activeCfg.servers.regions;

              # WIREGUARD
              WIREGUARD_ADDRESSES = activeCfg.wireguard.addresses;
              WIREGUARD_ALLOWED_IPS = activeCfg.wireguard.allowedIPs;
              WIREGUARD_ENDPOINT_IP = activeCfg.wireguard.endpointIP;
              WIREGUARD_ENDPOINT_PORT = activeCfg.wireguard.endpointPort;
              WIREGUARD_IMPLEMENTATION = activeCfg.wireguard.implementation;
              WIREGUARD_PERSISTENT_KEEPALIVE_INTERVAL = "25s";
              WIREGUARD_PUBLIC_KEY = activeCfg.wireguard.publicKey;

              # PORT FORWARDING
              VPN_PORT_FORWARDING = activeCfg.portForwarding.enabled;
              PORT_FORWARD_ONLY = activeCfg.portForwarding.only;
              VPN_PORT_FORWARDING_PROVIDER = activeCfg.portForwarding.provider;
            };
            environmentFiles = [
              # gluetun reads its SERVER_NAMES from this file at every (re)start
              pfEnvFile
              "${config.sops.secrets."users/${username}/gluetun-${cfg.activeCfg}.env".path}"
            ];
            healthCmd = "CMD-SHELL /gluetun-entrypoint healthcheck";
            healthInterval = "30s";
            healthOnFailure = "kill";
            healthRetries = 3;
            healthStartPeriod = "20s";
            healthTimeout = "10s";
            image = "docker.io/qmcgaw/gluetun:v3.41.3";
            notify = "healthy";
            publishPorts = [
              "8090:8090/tcp" # qBittorrent WEBUI_PORT
            ];

            volumes = [
              # bind mounts
              "${config.users.users.${username}.home}/.config/gluetun/wireguard:/gluetun/wireguard"
            ];
          };
          serviceConfig = {
            RestartSec = "10";
            Restart = "on-failure";
          };
        };
        pia-wg-refresh = {
          containerConfig = {
            autoStart = false;
            containerName = "pia-wg-refresh";
            image = "ghcr.io/ccarpinteri/pia-wg-refresh:v0.8.3";
            environments = {
              GLUETUN_CONTAINER = "gluetun";
              LOG_LEVEL = "info";
              # pia-wg-refresh writes to SERVER_NAMES (bind-mounted read-write) whenever the port/server changes
              ON_PORT_CHANGE_SCRIPT = "/hooks/update-server-name.sh";
              # tradeoff: will reliably work when the server changes but with the SAME PORT
              # (problematic with ON_PORT_CHANGE_SCRIPT) but will cause two restarts in a row on any given regen cycle
              ON_RECOVERY_SCRIPT = "/hooks/update-server-name.sh";
              PIA_PORT_FORWARDING = "true";
              PIA_REGION = activeCfg.piaRegion;
              WG_CONF_PATH = "/config/wg0.conf";
            };
            environmentFiles = [
              config.sops.secrets."users/${username}/wg-refresh-${cfg.activeCfg}.env".path
            ];
            volumes = [
              "${pfEnvDir}:/hostenv"
              "${updateServerNameScript}:/hooks/update-server-name.sh:ro"
              "${config.users.users.${username}.home}/.config/gluetun/wireguard:/config"
              "/var/run/docker.sock:/var/run/docker.sock"
              "/var/log/pia-wg-refresh:/logs"
            ];
          };
          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "10";
          };
          unitConfig = {
            After = [ "gluetun.service" ];
            Requires = [ "gluetun.service" ];
          };
        };
        # see the wiki at https://github.com/qbittorrent/qBittorrent/wiki
        qbittorrent =
          let
            qbtContainerConfDir = "${config.users.users.${username}.home}/.config/qbittorrent-container";
            qbtPinnedSettingsFile = (pkgs.formats.ini { }).generate "qbittorrent-pinned.ini" {
              Preferences = {
                "WebUI\\LocalHostAuth" = false;
              };
              BitTorrent = {
                "Session\\DefaultSavePath" = "/downloads/completed";
                # these two settings recommended in the docs,
                # see https://github.com/qdm12/gluetun-wiki/blob/main/setup/popular-apps.md
                "Session\\Interface" = "tun0";
                "Session\\InterfaceAddress" = "0.0.0.0";
                "Session\\TempPath" = "/downloads/incomplete";
                "Session\\TempPathEnabled" = true;
              };
            };
          in
          {
            containerConfig = {
              image = "docker.io/linuxserver/qbittorrent:latest";
              network = "container:gluetun"; # joins gluetun's netns — no ports of its own
              environments = {
                PUID = toString config.users.users.${username}.uid;
                PGID = toString config.users.groups.users.gid;
                WEBUI_PORT = "8090";
              };
              volumes = [
                "${qbtContainerConfDir}:/config"
                "${config.users.users.${username}.home}/Downloads/qbittorrent:/downloads"
              ];
            };
            serviceConfig = {
              ExecStartPre = pkgs.writeShellScript "pin-qbittorrent-settings" ''
                conf="${qbtContainerConfDir}/qBittorrent/qBittorrent.conf"
                if [ -f "$conf" ]; then
                  ${pkgs.crudini}/bin/crudini --merge "$conf" < ${qbtPinnedSettingsFile}
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
              Requires = [
                "gluetun.service"
              ];
            };
          };
        qbittorrent-port-forward = {
          containerConfig = {
            containerName = "qbittorrent-port-forward";
            image = "docker.io/mjmeli/qbittorrent-port-forward-gluetun-server:2025.12.21.02";
            network = "container:gluetun"; # same netns as gluetun + qbittorrent
            environments = {
              QBT_ADDR = "http://localhost:8090"; # matches your WEBUI_PORT
              GTN_ADDR = "http://localhost:8000"; # gluetun's default control server port
            };
            environmentFiles = [
              config.sops.secrets."users/${username}/qbittorrent-port-forward.env".path
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
            ];
          };
        };
      };
    };

    home-manager.users.${username} =
      { config, ... }:
      with lib;
      let
        inherit (config.lib.file) mkOutOfStoreSymlink;
      in
      {
        xdg.configFile = {
          # link without copying to nix store (manage externally) - must use absolute paths
          # no documentation of config file syntax is available, so use the GUI to write to an out-of-store file
          "qbittorrent-container" = {
            source = mkOutOfStoreSymlink "${config.home.homeDirectory}/${nix_repo}/system/nixos/modules/services/gluetun/qbittorrent-container";
          };
        };
      };
  };
}
