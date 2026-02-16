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
    # create a directory for the container bind mount
    home-manager.users.${username} = {
      xdg.configFile."paperless-gpt/prompts/.keep".text = "";
    };

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
      paperless-gpt = {
        restartIfChanged = false;
      };
      # postgresql.target.wantedBy = mkForce [ ];
    };
    # add the admin user to the paperless group
    users.users.${username}.extraGroups = [ "paperless" ];

    virtualisation.quadlet = {
      containers = {
        paperless-gpt = {
          autoStart = false;
          containerConfig = {
            autoUpdate = "registry";
            environmentFiles = [
              "${config.sops.secrets."users/${username}/paperless/ppless-gpt-${hostname}.env".path}"
            ];
            environments = {
              TZ = "Australia/Melbourne";
              PAPERLESS_BASE_URL = "http://localhost:28981";
              # PAPERLESS_PUBLIC_URL = "http://paperless.mydomain.com";
              MANUAL_TAG = "paperless-gpt";
              AUTO_TAG = "paperless-gpt-auto";
              OCR_PROVIDER = "llm"; # llm, google_docai, azure or docling
              # LLM Configuration
              LLM_PROVIDER = "openai"; # openai, mistral, ollama, or anthropic
              LLM_MODEL = "gpt-4o";
              VISION_LLM_PROVIDER = "openai"; # openai, ollama, mistral, or anthropic
              VISION_LLM_MODEL = "gpt-4o"; # minicpm-v (ollama) or gpt-4o (openai) or claude-sonnet-4-5 (anthropic/claude)
              # OLLAMA_HOST = "http://host.docker.internal:11434"; # If using Ollama
              # OCR Processing Mode
              OCR_PROCESS_MODE = "image"; # Optional, default: image, other options: pdf, whole_pdf
              PDF_SKIP_EXISTING_OCR = "false"; # Optional, skip OCR for PDFs with existing OCR
              # Enhanced OCR Features
              CREATE_LOCAL_HOCR = "false"; # Optional, save hOCR files locally
              LOCAL_HOCR_PATH = "/app/hocr"; # Optional, path for hOCR files
              CREATE_LOCAL_PDF = "false"; # Optional, save enhanced PDFs locally
              LOCAL_PDF_PATH = "/app/pdf"; # Optional, path for PDF files
              PDF_UPLOAD = "false"; # Optional, upload enhanced PDFs to paperless-ngx
              PDF_REPLACE = "false"; # Optional and DANGEROUS, delete original after upload
              PDF_COPY_METADATA = "true"; # Optional, copy metadata from original document
              PDF_OCR_TAGGING = "true"; # Optional, add tag to processed documents
              PDF_OCR_COMPLETE_TAG = "paperless-gpt-ocr-complete"; # Optional, tag name
              AUTO_OCR_TAG = "paperless-gpt-ocr-auto"; # Optional
              OCR_LIMIT_PAGES = "5"; # Optional, default: 5. Set to 0 for no limit.
              LOG_LEVEL = "info"; # Optional: debug, warn, error
            };
            # pull from the github container registry (ghcr)
            image = "ghcr.io/icereed/paperless-gpt:latest";
            networks = [ "host" ];
            noNewPrivileges = true;
            publishPorts = [ "8080:8080" ];
            volumes = [
              # bind mounts
              # "./prompts:/app/prompts" # Mount the prompts directory
              "${config.users.users.${username}.home}/.config/paperless-gpt/prompts:/apps/prompts" # Mount the prompts directory
              # "./hocr:/app/hocr" # Only if CREATE_LOCAL_HOCR is true
              # "./pdf:/app/pdf" # Only if CREATE_LOCAL_HOCR is true
            ];
          };
          serviceConfig = {
            RestartSec = "10";
            # Restart service when sleep finishes
            Restart = "always";
          };
        };
      };
      # networks = {
      #   internal.networkConfig.internal = [ "10.0.123.1/24" ];
      # };
    };
  };
}
