{
  config,
  hostname,
  inputs,
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
    sops.secrets."users/${username}/vaultwarden-${hostname}.env" = {
      sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      owner = "vaultwarden";
      group = "vaultwarden";
    };

    services.vaultwarden = {
      enable = true;

      # Injects ADMIN_TOKEN (and anything else you don't want in the Nix store)
      environmentFile = config.sops.secrets."users/${username}/vaultwarden-${hostname}.env".path;

      # sqlite is the default dbBackend, no need to set it explicitly

      backupDir = "/var/backup/vaultwarden";

      config = {
        DOMAIN = "https://vault.${inputs.secrets.domain.primary}"; # must match the resource hostname you create in Pangolin
        EMERGENCY_ACCESS_ALLOWED = true;
        SENDS_ALLOWED = true;
        SIGNUPS_ALLOWED = false;
        SIGNUPS_VERIFY = true;
        WEB_VAULT_ENABLED = true;

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
