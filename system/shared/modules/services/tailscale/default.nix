{
  config,
  lib,
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
      # Optional: pin a friendly hostname for this device on the tailnet
      # (otherwise it defaults to your system hostname).
      # extraUpFlags = [ "--hostname=laptop" ];
    };

    # Trust traffic arriving over the tailscale0 interface — this only
    # affects traffic between devices already inside your tailnet, it does
    # NOT expose anything to your LAN or the public internet.
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    # Allow Tailscale's own UDP traffic (NAT traversal / peer negotiation).
    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
