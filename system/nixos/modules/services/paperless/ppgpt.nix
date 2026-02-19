{
  config,
  hostname,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.paperless-ngx.ppgpt;
in
{
  options.mettavi.system.services.paperless-ngx.ppgpt = {
    enable = mkOption {
      type = types.bool;
      default = config.mettavi.system.services.paperless-ngx.withPaperlessGPT;
      description = "Enhance metadata and OCR scanning with the paperless-gpt addon";
    };
    llm = {
      generic = {
        provider = mkOption {
          type = types.str;
          default = "openai"; # openai, mistral, ollama, or anthropic
          description = "Which LLM provider to use";
        };
        model = mkOption {
          type = types.str;
          default = "gpt-4o";
          description = "Which LLM model to use";
        };
      };
      ocr = {
        provider = mkOption {
          type = types.str;
          default = "openai"; # openai, mistral, ollama, or anthropic
          description = "Which LLM provider to use for OCR";
        };
        model = mkOption {
          type = types.str;
          default = "gpt-4o"; # minicpm-v (ollama) or gpt-4o (openai) or claude-sonnet-4-5 (anthropic/claude)
          description = "Which LLM model to use for OCR";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # enable the ollama module if required
    mettavi.system.services.ollama.enable = mkIf (
      (cfg.llm.generic.provider == "ollama") || (cfg.llm.ocr.provider == "ollama")
    ) true;

    # DEFINE NON-DEFAULT OPTIONS HERE IF REQUIRED
    mettavi.system.services.paperless-ngx.llm = {
      generic = {
        provider = "ollama";
        model = "qwen3:8b";
      };
      ocr = {
        provider = "ollama";
        model = "minicpm-v:8b";
      };
    };

    # to enable and configure generic podman settings
    mettavi.system.services.podman.enable = true;

    # download LLMs with ollama if required
    services.ollama.loadModels =
      optionalString (cfg.llm.generic.provider == "ollama") [
        "${cfg.llm.generic.model}"
      ]
      ++ optionalString (cfg.llm.ocr.provider == "ollama") [
        "${cfg.llm.ocr.model}"
      ];

    sops.secrets = {
      "users/${username}/paperless/ppless-gpt-${hostname}.env" = paperlessSecrets;
    };
    # prevent the services from auto-starting on boot
    systemd.services = {
      paperless-gpt = {
        restartIfChanged = false;
      };
      # postgresql.target.wantedBy = mkForce [ ];
    };

    # create the directories that will be mounted in the paperless-gpt container
    systemd.tmpfiles.rules = [
      # type path mode user group (expiry)
      "d /var/lib/paperless/paperless-gpt 0770 paperless paperless -"
      "d /var/lib/paperless/paperless-gpt/prompts 0770 paperless paperless -"
      "d /var/lib/paperless/paperless-gpt/hocr 0770 paperless paperless -"
      "d /var/lib/paperless/paperless-gpt/pdf 0770 paperless paperless -"
      "d /var/lib/paperless/paperless-gpt/config 0770 paperless paperless -"
    ];

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
              # PAPERLESS_API_TOKEN  and OPENAI_API_KEY are loaded from the environment file "ppless-gpt-${hostname}.env"
              PAPERLESS_BASE_URL = "http://localhost:28981";
              # PAPERLESS_PUBLIC_URL = "http://paperless.mydomain.com";
              MANUAL_TAG = "paperless-gpt-manual";
              AUTO_TAG = "paperless-gpt-auto";

              # LLM Configuration (for non-OCR features)
              LLM_PROVIDER = "${cfg.llm.generic.provider}";
              LLM_MODEL = "${cfg.llm.generic.model}";
              LLM_LANGUAGE = "English";

              # Local LLM Configuration
              OLLAMA_HOST = "http://localhost:11434";
              # NB: the following two parameters are used for metadata processing, not OCR
              # Sets Ollama NumCtx (context window); if unset, model default is used
              # NB: If you hit "context length exceeded" or memory issues, reduce or choose a smaller model/context size
              # OLLAMA_CONTEXT_LENGTH = "8192";
              # NB: Lower this value if you see truncated or incomplete responses
              TOKEN_LIMIT = "2000"; # recommended for smaller models

              # OCR Configuration
              OCR_PROVIDER = "llm"; # llm, google_docai, azure or docling
              VISION_LLM_PROVIDER = "${cfg.llm.ocr.provider}";
              VISION_LLM_MODEL = "${cfg.llm.ocr.model}";

              # OCR Processing Mode
              OCR_PROCESS_MODE = "image"; # Optional, default: image, other options: pdf, whole_pdf
              PDF_SKIP_EXISTING_OCR = "false"; # Optional, skip OCR for PDFs with existing OCR

              # Enhanced OCR Features
              CREATE_LOCAL_HOCR = "true"; # Optional, save hOCR files locally
              LOCAL_HOCR_PATH = "/app/hocr"; # Optional, path for hOCR files
              CREATE_LOCAL_PDF = "true"; # Optional, save enhanced PDFs locally
              LOCAL_PDF_PATH = "/app/pdf"; # Optional, path for PDF files
              PDF_UPLOAD = "true"; # Optional, upload enhanced PDFs to paperless-ngx
              PDF_REPLACE = "false"; # Optional and DANGEROUS, delete original after upload
              PDF_COPY_METADATA = "true"; # Optional, used with PDF_UPLOAD, copy metadata from original document
              PDF_OCR_TAGGING = "true"; # Optional, add tag to processed documents
              PDF_OCR_COMPLETE_TAG = "paperless-gpt-ocr-complete"; # Optional, tag name
              AUTO_OCR_TAG = "paperless-gpt-ocr-auto"; # Optional
              OCR_LIMIT_PAGES = "0"; # Optional, default: 5. Set to 0 for no limit.
              LOG_LEVEL = "info"; # Optional: debug, warn, error
            };
            # pull from the github container registry (ghcr)
            image = "ghcr.io/icereed/paperless-gpt:latest";
            # give the container access to the host network
            networks = [ "host" ];
            noNewPrivileges = true;
            publishPorts = [ "8080:8080" ];
            volumes = [
              # bind mounts
              "${config.services.paperless.dataDir}/paperless-gpt/prompts:/app/prompts"
              "${config.services.paperless.dataDir}/paperless-gpt/hocr:/app/hocr" # Only if CREATE_LOCAL_HOCR is true
              "${config.services.paperless.dataDir}/paperless-gpt/pdf:/app/pdf" # Only if CREATE_LOCAL_PDF is true
              "${config.services.paperless.dataDir}/paperless-gpt/config:/app/config"
            ];
          };
          serviceConfig = {
            RestartSec = "10";
            # Restart service when sleep finishes
            Restart = "always";
          };
        };
      };
    };
  };
}
