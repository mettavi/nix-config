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
  # volumes = config.virtualisation.quadlet.volumes;
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
            endpoint_port = mkOption {
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
              type = bool;
              default = true;
              desription = "Whether to turn port forwarding on";
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
    # users.users.${username} = {
    # required for auto start before user login
    # linger = true;
    # required for rootless container with multiple users
    # autoSubUidGidRange = true;
    # };

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
              LOG_LEVEL = "INFO";
              # select servers with port forwarding only
              PORT_FORWARD_ONLY = false;
              SERVICE_REGIONS = "Australia";
              VPN_SERVICE_PROVIDER = cfg.vpn_provider;
              VPN_TYPE = "wireguard";
              VPN_PORT_FORWARDING = "on";
              VPN_PORT_FORWARDING_PROVIDER = "private internet access";
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
