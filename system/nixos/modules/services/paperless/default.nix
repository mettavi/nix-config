{
  config,
  hostname,
  lib,
  pkgs,
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
  imports = [ ./ppgpt.nix ];

  options.mettavi.system.services.paperless-ngx = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and setup paperless-ngx, a documents database tool";
    };
    withPaperlessGPT = mkOption {
      type = types.bool;
      default = true;
      description = "Enhance metadata and OCR scanning with the paperless-gpt addon";
    };
  };

  config = mkIf cfg.enable {
    services.paperless =
      let
        dataDir = "/var/lib/paperless";
      in
      {
        enable = true;
        # NB: Some of the recommended settings for nginx for paperless do not work on the nixos module
        # (https://github.com/paperless-ngx/paperless-ngx/wiki/Using-a-Reverse-Proxy-with-Paperless-ngx#nginx)
        address = "127.0.0.1";
        # configure Tika and Gotenberg to process Office and e-mail files with OCR
        # NOTE: When adding Gmail Oauth, always use the localhost address, NOT the virtual host address
        # eg. load the site at http://localhost:<port>, not http://pp.oona, to prevent a security error

        # PS The Gmail Oauth client for paperless is set to "published" to increase the timeout on the refresh token
        configureTika = true;
        consumptionDir = "${dataDir}/consume";
        # true sets permissions to 777
        # prefer adding the admin user to the paperless directory for hardened security (see below)
        consumptionDirIsPublic = false;
        # Configure a local PostgreSQL database server
        # NB: This sets PAPERLESS_DBENGINE = "postgresql";
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
            # do not touch the database dumps in this directory
            delete = mkForce false;
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
          # the folder needs to already exist (see systemd.tmpfiles below)
          PAPERLESS_EMPTY_TRASH_DIR = "/var/lib/paperless/Trash";
          # PAPERLESS_FILENAME_FORMAT = "{{document_type}}/{{created_year}}/{{title}}_{{created}}";
          PAPERLESS_OAUTH_CALLBACK_BASE_URL = "http://localhost:28981";
          PAPERLESS_OCR_LANGUAGE = "eng";
          PAPERLESS_OCR_USER_ARGS = {
            optimize = 1;
            pdfa_image_compression = "lossless";
          };
          PAPERLESS_TIME_ZONE = "Australia/Melbourne";
          # required when using a reverse proxy (eg. nginx)
          PAPERLESS_URL = "http://localhost:28981";
        };
        user = "paperless";
      };

    # if using postgresql, enable the system postgresql module to allow additional configuration
    mettavi.system.services.postgresql.enable = config.services.paperless.database.createLocally;

    sops.secrets = {
      "users/${username}/paperless/ppless-${hostname}.env" = paperlessSecrets;
      "users/${username}/paperless/ppless-${hostname}-pw" = paperlessSecrets;
    };
    systemd.services = {
      # don't autostart these services
      paperless-scheduler.wantedBy = mkForce [ ];
      redis-paperless.wantedBy = mkForce [ ];
      # postgresql.target.wantedBy = mkForce [ ];
    };
    # if the exporter schedule is missed, run it when the system is online
    systemd.timers = {
      paperless-exporter = {
        timerConfig = {
          Persistent = true;
        };
      };
    };
    # create the Trash directory
    systemd.tmpfiles.rules = [
      # type path mode user group (expiry) (argument)
      "d /var/lib/paperless/Trash 0770 paperless paperless -"
    ];
    # add the admin user to the paperless group
    users.users.${username}.extraGroups = [ "paperless" ];
  };
}
