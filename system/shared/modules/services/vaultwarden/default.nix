{
  config,
  lib,
  secrets_path,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.vaultwarden;
in
{
  options.mettavi.system.services.vaultwarden = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and set up vaultwarden";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."vaultwarden.env" = {
      sopsFile = "${secrets_path}/secrets/hosts/<app-host>.yaml"; # adjust to your app VPS's sops file
      owner = "vaultwarden";
      group = "vaultwarden";
    };

    services.vaultwarden = {
      enable = true;

      # Injects ADMIN_TOKEN (and anything else you don't want in the Nix store)
      environmentFile = config.sops.secrets."vaultwarden.env".path;

      # sqlite is the default dbBackend, no need to set it explicitly

      backupDir = "/var/lib/vaultwarden-backup";

      config = {
        DOMAIN = "https://vault.mettavi.cloud"; # must match the resource hostname you create in Pangolin
        SIGNUPS_ALLOWED = false;

        # Bind to loopback only — Pangolin/Traefik is the only thing that
        # should ever be able to reach this, via the site tunnel
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        ROCKET_LOG = "critical";

        # No SMTP configured yet — invites/2FA email will be unavailable
        # until you add SMTP_HOST / SMTP_PORT / SMTP_FROM / etc.
      };
    };

    # Nothing to open in the firewall: Vaultwarden only listens on
    # 127.0.0.1, reachable solely through the Pangolin tunnel/newt client
    # you'll run on this host.
  };
}
