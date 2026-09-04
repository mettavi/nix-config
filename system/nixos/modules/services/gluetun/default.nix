{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.mettavi.system.services.gluetun;
in
{
  options.mettavi.system.services.gluetun = {
    enable = mkEnableOption "Install and set up the Gluetun VPN service";
    providers = mkOption {
      type = attrsOf (submodule {
        options = {
          name = mkOption {
            type = str;
            default = "custom";
            description = "Provider name";
          };
          type = mkOption {
            type = enum [
              "openvpn"
              "wireguard"
            ];
            default = wireguard;
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
            regions = mkOption {
              type = str;
              default = "";
              description = "Comma separated list of VPN regions";
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
              type = bool;
              default = false;
              description = "Whether to only select servers with port forwarding";
            };
            provider = mkOption {
              type = str;
              default = "private internet access";
              description = "The provider of the port forwarding service";
            };
            username = mkOption {
              type = str;
              default = "";
              description = "The username for the provider";
            };
            password = mkOption {
              type = str;
              default = "";
              description = "The password for the provider";
            };
          };
          wireguard = {
            # IP network interface address in the format xx.xx.xx.xx/xx
            addresses = mkOption {
              type = listOf str;
              default = "";
              description = "Wireguard IP addresses";
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
            presharedKey = mkOption {
              type = str;
              default = "";
              description = "The password for the OpenVPN provider";
            };
            privateKey = mkOption {
              type = str;
              default = "";
              description = "The password for the OpenVPN provider";
            };
            publicKey = mkOption {
              type = str;
              default = "";
              description = "The username for the OpenVPN provider";
            };
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    # to enable and configure generic podman settings
    mettavi.system.services.podman.enable = true;

    environment.systemPackages = with pkgs; [ linpkgs.pia-wg-config ];

    sops.secrets = {
      # .env file for use with systemd service for PIA VPN
      "users/${username}/pia.env" = { };
    };

    virtualisation.quadlet = {
      containers = {
        gluetun = {
          autoStart = false;
          containerConfig = {
            addCapabilities = [
              "NET_ADMIN"
              "NET_RAW"
            ];
            devices = [ "/dev/net/tun:/dev/net/tun" ];
            environments = {
              # GENERAL
              VPN_SERVICE_PROVIDER = cfg.providers.name;
              VPN_TYPE = cfg.providers.type;
              LOG_LEVEL = "INFO";
              UPDATER_PERIOD = "480h";
              SERVER_NAMES = cfg.providers.servers.names;
              SERVICE_REGIONS = "Australia";

              # WIREGUARD

              # PORT FORWARDING
              VPN_PORT_FORWARDING = cfg.providers.portForwarding.enabled;
              PORT_FORWARD_ONLY = cfg.providers.portForwarding.only;
              VPN_PORT_FORWARDING_PROVIDER = cfg.providers.portForwarding.provider;
            };
            environmentFiles = [ "${config.sops.secrets."users/${username}/pia.env".path}" ];
            healthCmd = "CMD-SHELL /gluetun-entrypoint healthcheck";
            healthInterval = "30s";
            healthOnFailure = "kill";
            healthRetries = 3;
            healthStartPeriod = "20s";
            healthTimeout = "10s";
            image = "docker.io/qmcgaw/gluetun:v3.41.3";
            notify = "healthy";
            publishPorts = [
              "8888:8888/tcp" # HTTP proxy
              "8388:8388/tcp" # Shadowsocks
              "8388:8388/udp" # Shadowsocks
            ];

            volumes = [
              # bind mounts
              "${config.users.users.${username}.home}/.config/gluetun:/gluetun"
            ];
          };
          serviceConfig = {
            RestartSec = "10";
            Restart = "on-failure";
          };
        };
      };
    };
  };
}
