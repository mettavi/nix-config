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
  cfg = config.mettavi.system.services.paperless-redux;

  # =========================================================================
  # 1. DEFINE INSTANCES HERE
  # =========================================================================
  instances = {
    personal = {
      alias = "pp";
      appPort = 28981;
      gptPort = 8081;
      redisDbIndex = 1;
    };
    genealogy = {
      alias = "ppg";
      appPort = 28982;
      gptPort = 8082;
      redisDbIndex = 2;
    };
  };

  paperlessSecrets = {
    group = "${config.users.users.paperless.name}";
    mode = "0440";
    sopsFile = "${secrets_path}/secrets/apps/paperless.yaml";
  };
in
{
  # Options block remains unchanged to preserve your public API layout
  options.mettavi.system.services.paperless-redux = {
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
    ppgpt.enable = mkOption {
      type = types.bool;
      default = cfg.enable && cfg.withPaperlessGPT;
      description = "Enhance metadata and OCR scanning with the paperless-gpt addon";
    };
    ppgpt.llm.generic = {
      provider = mkOption {
        type = types.str;
        default = "ollama";
      };
      model = mkOption {
        type = types.str;
        default = "qwen3:8b";
      };
    };
    ppgpt.llm.ocr = {
      provider = mkOption {
        type = types.str;
        default = "ollama";
      };
      model = mkOption {
        type = types.str;
        default = "minicpm-v:8b";
      };
    };
  };

  config = mkIf cfg.enable {
    # System user settings
    users.users.paperless = {
      isSystemUser = true;
      group = "paperless";
      uid = config.ids.uids.paperless;
    };
    users.groups.paperless = {
      gid = config.ids.gids.paperless;
    };

    # add the admin user to the paperless group
    users.users.${username}.extraGroups = [ "paperless" ];

    networking.firewall.trustedInterfaces = [ "podman1" ];

    mettavi.system.services.podman.enable = true;
    mettavi.system.services.ollama.enable = mkIf (
      (cfg.ppgpt.llm.generic.provider == "ollama") || (cfg.ppgpt.llm.ocr.provider == "ollama")
    ) true;

    services.ollama.loadModels =
      optionalString (cfg.ppgpt.llm.generic.provider == "ollama") [ "${cfg.ppgpt.llm.generic.model}" ]
      ++ optionalString (cfg.ppgpt.llm.ocr.provider == "ollama") [ "${cfg.ppgpt.llm.ocr.model}" ];

    # add paperless databases to the postgresqlBackup module
    services.postgresqlBackup.databases = flatten (
      mapAttrsToList (name: _: [
        "paperless_${name}"
      ]) instances
    );

    sops.secrets = {
      "users/${username}/paperless/ppless-${hostname}.env" = paperlessSecrets;
    }
    // (mapAttrs' (
      name: inst:
      nameValuePair "users/${username}/paperless/ppless-gpt-${name}-${hostname}.env" {
        group = "${config.users.users.paperless.name}";
        mode = "0440";
        sopsFile = "${secrets_path}/secrets/apps/paperless.yaml";
      }
    ) instances);

    # =========================================================================
    # 2. DYNAMIC DIRECTORY GENERATION & ACL PERMISSIONS
    # Incorporates the explicit 0770 base permissioning and systemic
    # POSIX ACL rules ensuring Gramps can permanently read the media tree.
    # =========================================================================
    systemd.tmpfiles.rules = [
      "d /var/lib/paperless/Trash 0770 paperless paperless -"
    ]
    ++ (flatten (
      mapAttrsToList (name: _: [
        # Standard Directory Creation (Enforcing 0751 / 0770 strictly matching your fix)
        "d /var/lib/paperless/${name} 0770 paperless paperless -"
        "d /var/lib/paperless/${name}/consume 0770 paperless paperless -"
        "d /var/lib/paperless/${name}/media 0770 paperless paperless -"
        "d /var/lib/paperless/${name}/data 0700 paperless paperless -"
        "d /var/lib/paperless/${name}/export 0770 paperless paperless -"
        "d /var/lib/paperless/${name}/paperless-gpt 0770 paperless paperless -"
        "d /var/lib/paperless/${name}/paperless-gpt/prompts 0770 paperless paperless -"
        "d /var/lib/paperless/${name}/paperless-gpt/hocr 0770 paperless paperless -"
        "d /var/lib/paperless/${name}/paperless-gpt/pdf 0770 paperless paperless -"
        "d /var/lib/paperless/${name}/paperless-gpt/config 0770 paperless paperless -"

        # POSIX ACL Layer: Forces 'paperless' group rwX inheritance on the dynamic instances
        "a+ /var/lib/paperless/${name}/media - - - - g:paperless:rwX"
        "a+ /var/lib/paperless/${name}/media - - - - d:g:paperless:rwX"
      ]) instances
    ));

    # =========================================================================
    # 3. DYNAMIC CONTAINER GENERATION via Quadlet
    # =========================================================================
    virtualisation.quadlet = {
      autoUpdate.enable = true;
      networks.paperless-net = { };

      containers = {
        # Shared Caching Engine
        paperless-redis = {
          containerConfig = {
            image = "docker.io/library/redis:7-alpine";
            networks = [ config.virtualisation.quadlet.networks.paperless-net.ref ];
          };
        };
      }
      # Dynamically inject the generated app instances into the container list
      // (mapAttrs' (
        name: inst:
        nameValuePair "paperless-${name}" {
          containerConfig = {
            image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
            autoUpdate = "registry";
            networks = [ config.virtualisation.quadlet.networks.paperless-net.ref ];
            publishPorts = [ "127.0.0.1:${toString inst.appPort}:8000" ];

            environmentFiles = [
              config.sops.secrets."users/${username}/paperless/ppless-${hostname}.env".path
            ];

            environments = {
              # required when using a reverse proxy (eg. nginx)
              PAPERLESS_URL = "http://${inst.alias}.${hostname}";
              # also requires PAPERLESS_ADMIN_PASSWORD to be set (in the env file)
              PAPERLESS_ADMIN_USER = "admin";
              PAPERLESS_APP_TITLE = lib.toSentenceCase "${name}" + " Archive";
              PAPERLESS_REDIS = "redis://paperless-redis:6379/${toString inst.redisDbIndex}";
              # PAPERLESS_TIME_ZONE = "Australia/Melbourne";
              PAPERLESS_TIME_ZONE = "America/Los_Angeles";
              PAPERLESS_OCR_LANGUAGE = "eng";
              PAPERLESS_DATE_PARSER_LANGUAGES = "en-AU";
              PAPERLESS_CONSUMER_RECURSIVE = "true";
              PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = "true";
              # where documents are deleted (after emptying the trash)
              # NB: this is the path in the container, see https://github.com/paperless-ngx/paperless-ngx/discussions/2131
              PAPERLESS_EMPTY_TRASH_DIR = "/usr/src/paperless/Trash";
              # ARGUMENTS TO PASS TO OCRMYPDF (requires a json object):
              # other options for USER_ARGS (see below):
              # when pdf importing fails, print to a new pdf or set the variable below
              # continue_on_soft_render_error = true;
              PAPERLESS_OCR_USER_ARGS = ''
                {"deskew": true, "optimize": 1, "pdfa_image_compression": "lossless"}
              '';

              PAPERLESS_OAUTH_CALLBACK_BASE_URL = "http://localhost:${toString inst.appPort}";

              # --- CRITICAL PERMISSION WRAPPER OVERRIDES ---
              UMASK = "0007"; # Forces internal paperless workers to spawn files/directories with 660/770 permissions
              UMASK_SET = "007";
              USERMAP_UID = toString config.users.users.paperless.uid;
              USERMAP_GID = toString config.users.groups.paperless.gid;

              # configure the postgres DB
              PAPERLESS_DBENGINE = "postgresql";
              PAPERLESS_DBHOST = "10.89.0.1"; # Routes directly out to the host system
              PAPERLESS_DBPORT = "5432";
              PAPERLESS_DBNAME = "paperless_${name}";
              PAPERLESS_DBUSER = "paperless";

              # use Tika and Gotenberg for parsing and converting "Office" documents
              PAPERLESS_TIKA_ENABLED = "true";
              PAPERLESS_TIKA_ENDPOINT = "http://localhost:9998";
              PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://localhost:3000";
            };

            volumes = [
              "/var/lib/paperless/${name}/data:/usr/src/paperless/data"
              "/var/lib/paperless/${name}/export:/usr/src/paperless/export"
              "/var/lib/paperless/${name}/media:/usr/src/paperless/media"
              "/var/lib/paperless/${name}/consume:/usr/src/paperless/consume"
              "/var/lib/paperless/Trash:/usr/src/paperless/Trash"
            ];
          };
        }
      ) instances)

      # Dynamically inject the generated GPT instances into the container list (if enabled)
      // (
        if cfg.ppgpt.enable then
          (mapAttrs' (
            name: inst:
            nameValuePair "paperless-gpt-${name}" {
              containerConfig = {
                image = "ghcr.io/icereed/paperless-gpt:latest";
                autoUpdate = "registry";
                noNewPrivileges = true;
                networks = [ config.virtualisation.quadlet.networks.paperless-net.ref ];
                publishPorts = [ "127.0.0.1:${toString inst.gptPort}:8080" ];

                environmentFiles = [
                  config.sops.secrets."users/${username}/paperless/ppless-gpt-${name}-${hostname}.env".path
                ];

                environments = {
                  TZ = "Australia/Melbourne";
                  UMASK = "0007"; # Retained to align metadata files
                  PAPERLESS_BASE_URL = "http://paperless-${name}:8000";
                  OLLAMA_HOST = "http://10.89.0.1:11434";
                  OLLAMA_CONTEXT_LENGTH = "16384";
                  TOKEN_LIMIT = "4096";
                  MANUAL_TAG = "paperless-gpt-manual";
                  AUTO_TAG = "paperless-gpt-auto";
                  AUTO_GENERATE_TITLE = "true";
                  AUTO_GENERATE_TAGS = "true";
                  AUTO_GENERATE_CORRESPONDENTS = "true";
                  AUTO_GENERATE_DOCUMENT_TYPE = "true";
                  AUTO_GENERATE_CREATED_DATE = "true";
                  LLM_PROVIDER = "${cfg.ppgpt.llm.generic.provider}";
                  LLM_MODEL = "${cfg.ppgpt.llm.generic.model}";
                  LLM_LANGUAGE = "English";
                  OCR_PROVIDER = "llm";
                  VISION_LLM_PROVIDER = "${cfg.ppgpt.llm.ocr.provider}";
                  VISION_LLM_MODEL = "${cfg.ppgpt.llm.ocr.model}";
                  VISION_LLM_MAX_TOKENS = "2048";
                  OCR_PROCESS_MODE = "image";
                  PDF_SKIP_EXISTING_OCR = "false";
                  PDF_OCR_TAGGING = "true"; # Optional, add tag to processed documents
                  PDF_OCR_COMPLETE_TAG = "paperless-gpt-ocr-complete"; # Optional, tag name
                  OCR_LIMIT_PAGES = "0"; # Optional, default: 5. Set to 0 for no limit.
                  # NB: View the logs with 'journalctl -u paperless-gpt.service -f'
                  LOG_LEVEL = "info"; # Optional: debug, info, warn, error
                };

                volumes = [
                  "/var/lib/paperless/${name}/paperless-gpt/prompts:/app/prompts"
                  "/var/lib/paperless/${name}/paperless-gpt/hocr:/app/hocr"
                  "/var/lib/paperless/${name}/paperless-gpt/pdf:/app/pdf"
                  "/var/lib/paperless/${name}/paperless-gpt/config:/app/config"
                  "/var/lib/paperless/${name}/media:/app/media:z"
                ];
              };
              serviceConfig = {
                RestartSec = "10";
                Restart = "on-failure";
                UMask = "0007";
              };
            }
          ) instances)
        else
          { }
      );
    };
    home-manager.users.${username} =
      { nixosConfig, ... }:
      {
        gtk.gtk3.bookmarks = optionals nixosConfig.mettavi.system.services.paperless-redux.enable flatten (
          mapAttrsToList (name: _: [
            "file:///var/lib/paperless/${name}/consume pp-${name}"
          ]) instances
        );
      };
  };
}
