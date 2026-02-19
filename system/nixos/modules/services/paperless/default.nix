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
      "users/${username}/paperless/ppless-${hostname}.env" = paperlessSecrets;
      "users/${username}/paperless/ppless-${hostname}-pw" = paperlessSecrets;
    };
    # prevent the services from auto-starting on boot
    systemd.services = {
      redis-paperless.wantedBy = mkForce [ ];
      paperless-scheduler.wantedBy = mkForce [ ];
      # postgresql.target.wantedBy = mkForce [ ];
    };
    # add the admin user to the paperless group
    users.users.${username}.extraGroups = [ "paperless" ];
  };

  # (mkIf cfg.withPaperlessGPT {
  #   # enable the ollama module if required
  #   mettavi.system.services.ollama.enable = mkIf (
  #     (cfg.llm.generic.provider == "ollama") || (cfg.llm.ocr.provider == "ollama")
  #   ) true;
  #
  #   # DEFINE NON-DEFAULT OPTIONS HERE IF REQUIRED
  #   mettavi.system.services.paperless-ngx.llm = {
  #     generic = {
  #       provider = "ollama";
  #       model = "qwen3:8b";
  #     };
  #     ocr = {
  #       provider = "ollama";
  #       model = "minicpm-v:8b";
  #     };
  #   };
  #
  #   # to enable and configure generic podman settings
  #   mettavi.system.services.podman.enable = true;
  #
  #   services.ollama.loadModels =
  #     optionalString (cfg.llm.generic.provider == "ollama") [
  #       "${cfg.llm.generic.model}"
  #     ]
  #     ++ optionalString (cfg.llm.ocr.provider == "ollama") [
  #       "${cfg.llm.ocr.model}"
  #     ];
  #
  #   sops.secrets = {
  #     "users/${username}/paperless/ppless-gpt-${hostname}.env" = paperlessSecrets;
  #   };
  #   # prevent the services from auto-starting on boot
  #   systemd.services = {
  #     paperless-gpt = {
  #       restartIfChanged = false;
  #     };
  #     # postgresql.target.wantedBy = mkForce [ ];
  #   };
  #
  #   # create the directories that will be mounted in the paperless-gpt container
  #   systemd.tmpfiles.rules = [
  #     # type path mode user group (expiry)
  #     "d /var/lib/paperless/paperless-gpt 0770 paperless paperless -"
  #     "d /var/lib/paperless/paperless-gpt/prompts 0770 paperless paperless -"
  #     "d /var/lib/paperless/paperless-gpt/hocr 0770 paperless paperless -"
  #     "d /var/lib/paperless/paperless-gpt/pdf 0770 paperless paperless -"
  #     "d /var/lib/paperless/paperless-gpt/config 0770 paperless paperless -"
  #   ];
  #
  #   virtualisation.quadlet = {
  #     containers = {
  #       paperless-gpt = {
  #         autoStart = false;
  #         containerConfig = {
  #           autoUpdate = "registry";
  #           environmentFiles = [
  #             "${config.sops.secrets."users/${username}/paperless/ppless-gpt-${hostname}.env".path}"
  #           ];
  #           environments = {
  #             TZ = "Australia/Melbourne";
  #             # PAPERLESS_API_TOKEN  and OPENAI_API_KEY are loaded from the environment file "ppless-gpt-${hostname}.env"
  #             PAPERLESS_BASE_URL = "http://localhost:28981";
  #             # PAPERLESS_PUBLIC_URL = "http://paperless.mydomain.com";
  #             MANUAL_TAG = "paperless-gpt-manual";
  #             AUTO_TAG = "paperless-gpt-auto";
  #
  #             # LLM Configuration (for non-OCR features)
  #             LLM_PROVIDER = "${cfg.llm.generic.provider}";
  #             LLM_MODEL = "${cfg.llm.generic.model}";
  #             LLM_LANGUAGE = "English";
  #
  #             # Local LLM Configuration
  #             OLLAMA_HOST = "http://localhost:11434";
  #             # NB: the following two parameters are used for metadata processing, not OCR
  #             # Sets Ollama NumCtx (context window); if unset, model default is used
  #             # NB: If you hit "context length exceeded" or memory issues, reduce or choose a smaller model/context size
  #             # OLLAMA_CONTEXT_LENGTH = "8192";
  #             # NB: Lower this value if you see truncated or incomplete responses
  #             TOKEN_LIMIT = "2000"; # recommended for smaller models
  #
  #             # OCR Configuration
  #             OCR_PROVIDER = "llm"; # llm, google_docai, azure or docling
  #             VISION_LLM_PROVIDER = "${cfg.llm.ocr.provider}";
  #             VISION_LLM_MODEL = "${cfg.llm.ocr.model}";
  #
  #             # OCR Processing Mode
  #             OCR_PROCESS_MODE = "image"; # Optional, default: image, other options: pdf, whole_pdf
  #             PDF_SKIP_EXISTING_OCR = "false"; # Optional, skip OCR for PDFs with existing OCR
  #
  #             # Enhanced OCR Features
  #             CREATE_LOCAL_HOCR = "true"; # Optional, save hOCR files locally
  #             LOCAL_HOCR_PATH = "/app/hocr"; # Optional, path for hOCR files
  #             CREATE_LOCAL_PDF = "true"; # Optional, save enhanced PDFs locally
  #             LOCAL_PDF_PATH = "/app/pdf"; # Optional, path for PDF files
  #             PDF_UPLOAD = "true"; # Optional, upload enhanced PDFs to paperless-ngx
  #             PDF_REPLACE = "false"; # Optional and DANGEROUS, delete original after upload
  #             PDF_COPY_METADATA = "true"; # Optional, used with PDF_UPLOAD, copy metadata from original document
  #             PDF_OCR_TAGGING = "true"; # Optional, add tag to processed documents
  #             PDF_OCR_COMPLETE_TAG = "paperless-gpt-ocr-complete"; # Optional, tag name
  #             AUTO_OCR_TAG = "paperless-gpt-ocr-auto"; # Optional
  #             OCR_LIMIT_PAGES = "0"; # Optional, default: 5. Set to 0 for no limit.
  #             LOG_LEVEL = "info"; # Optional: debug, warn, error
  #           };
  #           # pull from the github container registry (ghcr)
  #           image = "ghcr.io/icereed/paperless-gpt:latest";
  #           # give the container access to the host network
  #           networks = [ "host" ];
  #           noNewPrivileges = true;
  #           publishPorts = [ "8080:8080" ];
  #           volumes = [
  #             # bind mounts
  #             "${config.services.paperless.dataDir}/paperless-gpt/prompts:/app/prompts"
  #             "${config.services.paperless.dataDir}/paperless-gpt/hocr:/app/hocr" # Only if CREATE_LOCAL_HOCR is true
  #             "${config.services.paperless.dataDir}/paperless-gpt/pdf:/app/pdf" # Only if CREATE_LOCAL_PDF is true
  #             "${config.services.paperless.dataDir}/paperless-gpt/config:/app/config"
  #           ];
  #         };
  #         serviceConfig = {
  #           RestartSec = "10";
  #           # Restart service when sleep finishes
  #           Restart = "always";
  #         };
  #       };
  #     };
  #   };
  # })
}
