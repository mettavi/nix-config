{
  config,
  hostname,
  lib,
  secrets_path,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.tailscale;
in
{
  options.mettavi.system.services.tailscale = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and set up the tailscale service";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      # If you would like to use a preauthorized key, set
      # Note: maximum expire time is 90 days
      authKeyFile = config.sops.secrets."users/${username}/tailscale_key_${hostname}".path;
      # Optional: pin a friendly hostname for this device on the tailnet
      # (otherwise it defaults to your system hostname).
      # extraUpFlags = [ "--hostname=laptop" ];
    };

    sops.secrets = {
      "users/${username}/tailscale_key_${hostname}" = {
        # login automatically using an auth key
        sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      };
    };

    # Trust traffic arriving over the tailscale0 interface — this only
    # affects traffic between devices already inside your tailnet, it does
    # NOT expose anything to your LAN or the public internet.
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    # Allow Tailscale's own UDP traffic (NAT traversal / peer negotiation).
    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
