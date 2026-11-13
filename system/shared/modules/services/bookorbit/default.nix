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
    optional
    optionalAttrs
    ;
in
{
  options.mettavi.system.services.bookOrbit = {
    enable = mkEnableOption "Install and set up the BookOrbit self-hosted library platform";
  };

  config = mkMerge [
    # NB:use 'optionalAttrs'; 'mkIf' doesn’t stop “option does not exist” errors
    # Only defined on releases that actually declare services.bookorbit
    (optionalAttrs hasNewModule {
      services.bookorbit = mkIf cfg.enable {
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
    })
    (mkIf (cfg.enable && hasNewModule) {
      sops.secrets."users/${username}/bookorbit-${hostname}.env" = {
        sopsFile = "${secrets_path}/secrets/apps/bookorbit.yaml";
        owner = "bookorbit";
        group = "bookorbit";
      };
    })
    # make it obvious if you enable it on a release that lacks the module
    {
      warnings = optional (
        cfg.enable && !hasNewModule
      ) "bookOrbit is enabled but this nixpkgs has no services.bookorbit module; nothing was configured.";
    }
  ];
}
