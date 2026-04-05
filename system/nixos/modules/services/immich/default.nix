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
      # config file /run/immich/config.json
      # Setting it to null allows configuring Immich in the web interface.
      settings = {
        backup = {
          database = {
            cronExpression = "0 02 * * *";
            enabled = true;
            keepLastAmount = 14;
          };
        };
        ffmpeg = {
          accel = "nvenc";
          accelDecode = true;
          acceptedAudioCodecs = [
            "aac"
            "mp3"
            "libopus"
          ];
          acceptedContainers = [
            "mov"
            "ogg"
            "webm"
          ];
          acceptedVideoCodecs = [
            "h264"
          ];
          bframes = "-1";
          cqMode = "auto";
          crf = 23;
          gopSize = 0;
          maxBitrate = "0";
          preferredHwDevice = "auto";
          preset = "fast";
          refs = 0;
          targetAudioCodec = "aac";
          targetResolution = "720";
          targetVideoCodec = "h264";
          temporalAQ = true;
          threads = 0;
          tonemap = "hable";
          transcode = "required";
          twoPass = true;
        };
        image = {
          colorspace = "p3";
          extractEmbedded = false;
          fullsize = {
            enabled = false;
            format = "jpeg";
            progressive = false;
            quality = 80;
          };
          preview = {
            format = "jpeg";
            progressive = false;
            quality = 80;
            size = 1440;
          };
          thumbnail = {
            format = "webp";
            progressive = false;
            quality = 80;
            size = 250;
          };
        };
        job = {
          backgroundTask = {
            concurrency = 5;
          };
          editor = {
            concurrency = 2;
          };
          faceDetection = {
            concurrency = 2;
          };
          library = {
            concurrency = 5;
          };
          metadataExtraction = {
            concurrency = 5;
          };
          migration = {
            concurrency = 5;
          };
          notifications = {
            concurrency = 5;
          };
          ocr = {
            concurrency = 1;
          };
          search = {
            concurrency = 5;
          };
          sidecar = {
            concurrency = 5;
          };
          smartSearch = {
            concurrency = 2;
          };
          thumbnailGeneration = {
            concurrency = 1;
          };
          videoConversion = {
            concurrency = 1;
          };
          workflow = {
            concurrency = 5;
          };
        };
        library = {
          scan = {
            cronExpression = "0 0 * * *";
            enabled = true;
          };
          watch = {
            enabled = false;
          };
        };
        logging = {
          enabled = true;
          level = "log";
        };
        machineLearning = {
          availabilityChecks = {
            enabled = true;
            interval = 30000;
            timeout = 2000;
          };
          clip = {
            enabled = true;
            modelName = "ViT-B-32__openai";
          };
          duplicateDetection = {
            enabled = true;
            maxDistance = 0.01;
            ocr = {
              enabled = true;
              maxResolution = 736;
              minDetectionScore = 0.5;
              minRecognitionScore = 0.8;
              modelName = "PP-OCRv5_mobile";
            };
            urls = [
              "http://localhost:3003"
            ];
          };
          map = {
            darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
            enabled = true;
            lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
          };
          metadata = {
            faces = {
              import = false;
            };
          };
          newVersionCheck = {
            enabled = true;
          };
          nightlyTasks = {
            clusterNewFaces = true;
            databaseCleanup = true;
            generateMemories = true;
            missingThumbnails = true;
            startTime = "00:00";
            syncQuotaUsage = true;
          };
          notifications = {
            smtp = {
              enabled = false;
              from = "";
              replyTo = "";
              transport = {
                host = "";
                ignoreCert = false;
                password = "";
                port = 587;
                secure = false;
                username = "";
              };
            };
          };
          oauth = {
            autoLaunch = false;
            autoRegister = true;
            buttonText = "Login with OAuth";
            clientId = "";
            clientSecret = "";
            defaultStorageQuota = null;
            enabled = false;
            issuerUrl = "";
            mobileOverrideEnabled = false;
            mobileRedirectUri = "";
            profileSigningAlgorithm = "none";
            roleClaim = "immich_role";
            scope = "openid email profile";
            signingAlgorithm = "RS256";
            storageLabelClaim = "preferred_username";
            storageQuotaClaim = "immich_quota";
            timeout = 30000;
            tokenEndpointAuthMethod = "client_secret_post";
          };
          passwordLogin = {
            enabled = true;
          };
          reverseGeocoding = {
            enabled = true;
          };
          server = {
            externalDomain = "";
            loginPageMessage = "";
            publicUsers = true;
          };
          storageTemplate = {
            enabled = false;
            hashVerificationEnabled = true;
            template = "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}";
          };
          templates = {
            email = {
              albumInviteTemplate = "";
              albumUpdateTemplate = "";
              welcomeTemplate = "";
            };
          };
          theme = {
            customCss = "";
          };
          trash = {
            days = 30;
            enabled = true;
          };
          user = {
            deleteDelay = 7;
          };
        };
      };
    };

    users.users.immich.extraGroups = [
      "video"
      "render"
    ];
  };
}
