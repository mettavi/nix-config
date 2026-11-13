{
  config,
  hostname,
  lib,
  modulesPath,
  secrets_path,
  username,
  ...
}:

let
  cfg = config.mettavi.system.services.bookOrbit;
  hasNewModule = builtins.pathExists (modulesPath + "/services/web-apps/bookorbit.nix");
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    optionalAttrs
    ;
  inherit (lib.types) str;
in
{
  options.mettavi.system.services.bookOrbit = {
    enable = mkEnableOption "Install and set up the BookOrbit self-hosted library platform";
    appUrl = mkOption {
      type = str;
      default = "http://localhost:3000";
      description = "The url where the app will be hosted";
    };
  };

  config = mkMerge [
    # NB:use 'optionalAttrs'; 'mkIf' doesn’t stop “option does not exist” errors
    # Only defined on releases that actually declare services.bookorbit
    (optionalAttrs hasNewModule {
      services.bookorbit = mkIf cfg.enable {
        enable = true;
        # POSTGRES_USER and POSTGRES_DB default to "bookorbit"
        createDatabaseLocally = true;
        # Environment variables to pass to the BookOrbit service.
        # See <https://bookorbit.app/installation.html#configuration> for available options.
        environment = {
          # Data storage directory.
          APP_DATA_PATH = "/var/lib/bookorbit";
          # The address you will use to open BookOrbit.
          # Direct LAN access: http://your-server-ip:3000
          # Behind a reverse proxy with a domain: https://books.example.com
          # Must match the public domain configured in your Pangolin dashboard
          APP_URL = cfg.appUrl;
          LOG_LEVEL = "info";
          # TCP port for the BookOrbit server.
          PORT = "3000";
          # Required when running behind a reverse proxy like Traefik/Pangolin
          TRUST_PROXY = "true";
        };
        environmentFile = config.sops.secrets."users/${username}/bookorbit-${hostname}.env".path;
        user = "bookorbit";
        group = "bookorbit";
        # Keep false if Pangolin/Newt reaches this VPS over a private WireGuard tunnel.
        # Set to true ONLY if Pangolin connects to this VPS's public IP directly.
        openFirewall = false;
      };
    })
    (mkIf (cfg.enable && hasNewModule) {
      sops.secrets."users/${username}/bookorbit-${hostname}.env" = {
        sopsFile = "${secrets_path}/secrets/apps/bookorbit.yaml";
        owner = "bookorbit";
        group = "bookorbit";
      };

      # Allow admin user (via bookorbit group) to browse files BookOrbit organizes
      systemd.services.bookorbit.serviceConfig.UMask = "0007";

      # let NixOS enforce the directory structure and permissions on every rebuild
      systemd.tmpfiles.rules = [
        "d /srv/media 2770 bookorbit bookorbit -"
        "d /srv/media/audiobooks 2770 bookorbit bookorbit -"
        "d /srv/media/ebooks 2770 bookorbit bookorbit -"
        "d /srv/media/comics 2770 bookorbit bookorbit -"
      ];
      # add the admin user to the bookorbit group
      users.users.${username}.extraGroups = [ "bookorbit" ];
    })
    # make it obvious if you enable it on a release that lacks the module
    {
      warnings = optional (
        cfg.enable && !hasNewModule
      ) "bookOrbit is enabled but this nixpkgs has no services.bookorbit module; nothing was configured.";
    }
  ];
}
