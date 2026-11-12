{
  config,
  hostname,
  lib,
  secrets_path,
  username,
  ...
}:

let
  cfg = config.mettavi.system.services.bookOrbit;
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.mettavi.system.services.bookOrbit = {
    enable = mkEnableOption "Install and set up the BookOrbit self-hosted library platform";
  };

  config = mkIf cfg.enable {
    services = {
      bookorbit = {
        enable = true;
        createDatabaseLocally = true;
        environment = {
          APP_DATA_PATH = "/var/lib/bookorbit";
          APP_URL = "http://localhost:3000";
          BOOKS_HOST_PATH = "${config.users.users.${username}.home}/media/bookorbit";
          LOG_LEVEL = "info";
          PORT = "3000";
        };
        environmentFile = config.sops.secrets."users/${username}/bookorbit-${hostname}.env".path;
        user = "bookorbit";
        group = "bookorbit";
        openFirewall = false;
      };
    };

    sops.secrets."users/${username}/bookorbit-${hostname}.env" = {
      sopsFile = "${secrets_path}/secrets/apps/bookorbit.yaml";
      owner = "bookorbit";
      group = "bookorbit";
    };
  };
}
