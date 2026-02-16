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
  paperlessSecrets = {
    group = "${config.users.users.paperless.name}";
    mode = "0440";
    sopsFile = "${secrets_path}/secrets/apps/paperless.yaml";
  };
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
    # to enable and configure generic podman settings
    mettavi.system.services.podman.enable = true;
    services.paperless =
      let
        dataDir = "/var/lib/paperless";
      in
      {
        enable = true;
        address = "127.0.0.1";
        # configure Tika and Gotenberg to process Office and e-mail files with OCR
        configureTika = true;
        consumptionDir = "${dataDir}/consume";
        # true sets permissions to 777
        # prefer systemd.tmpfiles option for hardened security (see below)
        consumptionDirIsPublic = false;
        # Configure a local PostgreSQL database server
        database.createLocally = true;
        dataDir = "${dataDir}";
        environmentFile = config.sops.secrets."users/${username}/paperless/ppless-${hostname}.env".path;
        # enable automated daily backups
        exporter = {
          enable = true;
          directory = "${dataDir}/export";
          onCalendar = "01:30:00";
          settings = {
            compare-checksums = true;
            delete = true;
            no-color = true;
            no-progress-bar = true;
          };
        };
        mediaDir = "${dataDir}/media";
        # enable a workaround for document classifier timeouts
        openMPThreadingWorkaround = true;
        passwordFile = config.sops.secrets."users/${username}/paperless/ppless-${hostname}-pw".path;
        port = 28981;
        settings = {
          # PAPERLESS_CONSUMER_ENABLE_BARCODES = true;
          PAPERLESS_CONSUMER_RECURSIVE = true;
          PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
          # the language(s) in which most of your documents are written
          PAPERLESS_DATE_PARSER_LANGUAGES = "en-AU";
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
          # PAPERLESS_EMPTY_TRASH_DIR = "/home/.Trash-0";
          PAPERLESS_URL = "http://localhost:28981";
        };
      };
    sops.secrets = {
      "users/${username}/paperless/ppless-gpt-${hostname}.env" = paperlessSecrets;
      "users/${username}/paperless/ppless-${hostname}.env" = paperlessSecrets;
      "users/${username}/paperless/ppless-${hostname}-pw" = paperlessSecrets;
    };
    # prevent the services from auto-starting on boot
    systemd.services = {
      redis-paperless.wantedBy = mkForce [ ];
      paperless-scheduler.wantedBy = mkForce [ ];
      # postgresql.target.wantedBy = mkForce [ ];
    };
    # only allow sudo users (in group wheel) to use the consumption directory
    # (more secure than consumptionDirIsPublic option)
    systemd.tmpfiles.rules = [
      # type path mode user group (expiry)
      "d ${config.services.paperless.consumptionDir} 0775 paperless wheel -"
    ];
  };
}
