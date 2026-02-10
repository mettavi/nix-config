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
  cfg = config.mettavi.system.services.paperless-ngx;
  paperlessSecrets.sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
in
{
  options.mettavi.system.services.paperless-ngx = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and setup paperless-ngx, a documents database tool";
    };
  };

  config = mkIf cfg.enable {
    services.paperless = {
      enable = true;
      address = "127.0.0.1";
      # configure Tika and Gotenberg to process Office and e-mail files with OCR
      configureTika = true;
      # Configure a local PostgreSQL database server
      database.createLocally = true;
      dataDir = "${config.users.users.${username}.home}/.local/share/paperless";
      environmentFile = config.sops.secrets."users/${username}/paperless-${hostname}.env".path;
      mediaDir = "${config.users.users.${username}.home}/media/paperless";
      # enable a workaround for document classifier timeouts
      openMPThreadingWorkaround = true;
      passwordFile = config.sops.secrets."users/${username}/paperless-${hostname}-pw".path;
      port = 28981;
      settings = {
        # PAPERLESS_CONSUMER_ENABLE_BARCODES = true;
        PAPERLESS_CONSUMER_RECURSIVE = true;
        PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";
        # PAPERLESS_DBPASS is defined in the environmentFile (see above)
        PAPERLESS_OCR_LANGUAGE = "eng";
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
        };
        PAPERLESS_TIME_ZONE = "Australia/Melbourne";
        PAPERLESS_EMPTY_TRASH_DIR = "/home/.Trash-0";
        # PAPERLESS_URL = "https://paperless.example.com";
      };
    };
    sops.secrets = {
      "users/${username}/paperless-${hostname}.env" = paperlessSecrets;
      "users/${username}/paperless-${hostname}-pw" = paperlessSecrets;
    };
  };
}
