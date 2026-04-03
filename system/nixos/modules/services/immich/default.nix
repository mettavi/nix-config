{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.mettavi.system.services.immich;
in
{
  options.mettavi.system.services.immich = {
    enable = mkEnableOption "Install and configure immich for photos";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      immich-cli
      # immich-go # tool for bulk-uploads
    ];

    services.immich = {
      enable = true;
      user = "immich";
      group = "immich";
      # null gives access to all devices, or restrict like [ "/dev/dri/renderD128" ]
      accelerationDevices = null;
      database = {
        # enable the postgres db
        enable = true;
        createDB = true;
        # url or unix socket path
        host = "/run/postgresql";
        name = "immich";
        port = 5432;
        user = "immich";
      };
      environment = {
        IMMICH_CONFIG_FILE = "/run/immich/config.json";
        IMMICH_LOG_LEVEL = "log"; # verbose, debug, log, warn, error
        TZ = "Australia/Melbourne";
      };
      # localhost or 0.0.0.0 for unrestricted
      host = "0.0.0.0";
      # to detect faces and search for objects (uses port 3003)
      machine-learning = {
        enable = true;
        environment = {
          MACHINE_LEARNING_MODEL_TTL = "600";
        };
      };
      # sets IMMICH_MEDIA_LOCATION variable
      mediaLocation = "/var/lib/immich";
      openFirewall = true;
      port = 2283;
      redis.enable = true;
      # eg. file containing DB_PASSWORD=<pass>, IMMICH_API_KEY=<key>
      secretsFile = null;
      settings = { };
    };

    users.users.immich.extraGroups = [
      "video"
      "render"
    ];

  };
}
