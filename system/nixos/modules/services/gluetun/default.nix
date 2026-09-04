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
    vpn_provider = mkOption {
      description = "Specify the default VPN provider to connect to";
      type = enum [
        "private internet access" # private internet access
      ];
      default = "private internet access";
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
