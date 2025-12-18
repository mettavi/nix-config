{
  config,
  hostname,
  inputs,
  lib,
  username,
  ...
}:
let
  cfg = config.mettavi.system.services.jellarr;
  home = config.users.users.${username}.home;
in
{

  options.mettavi.system.services.jellarr = {
    enable = lib.mkEnableOption "Install and declaratively configure the jellyfin media server using the jellarr third-party flake";
  };

  config = lib.mkIf cfg.enable {
    # install and setup the jellyfin service
    mettavi.system.services.jellyfin.enable = true;

    # import the nixos jellarr module
    imports = [
      inputs.jellarr.nixosModules.default
    ];

    # configure the jellarr module
    services.jellarr = {
      enable = true;
      # NB: bootstrap only works if jellarr and jellyfin are on the same host
      bootstrap = {
        enable = true;
        apiKeyFile = config.sops.secrets."users/${username}/jellarr_apikey".path;
      };
      dataDir = "${home}/.local/share/jellarr";
      # not required if using the bootstrap option
      # environmentFile = config.sops.templates.jellarr-env.path;
      user = "${username}";
      group = "jellyfin";
      config = {
        version = 1;
        base_url = "http://localhost:8096";
        system = {
          enableMetrics = true; # Enable Prometheus metrics endpoint
          pluginRepositories = {
            name = "Jellyfin Stable";
            url = "https://repo.jellyfin.org/releases/plugin/manifest.json";
            enabled = true;
          };
          trickPlayOptions = {
            enableHwAcceleration = true;
            enableHwEncoding = true;
          };
        };
        branding = {
          splashScreenEnabled = false;
        };
        encoding = {
          enableHardwareEncoding = true;
          hardwareAccelerationType = "vaapi";
          vaapiDevice = "/dev/dri/renderD128";
          hardwareDecodingCodecs = [
            "h264"
            "hevc"
            "mpeg2video"
            "vc1"
            "vp8"
            "vp9"
            "av1"
          ];
          enableDecodingColorDepth10Hevc = true;
          enableDecodingColorDepth10Vp9 = true;
          enableDecodingColorDepth10HevcRext = true;
          enableDecodingColorDepth12HevcRext = true;
          allowHevcEncoding = false;
          allowAv1Encoding = false;
        };
        library = {
          virtualFolders = [
            {
              name = "Movies";
              collectionType = "movies";
              libraryOptions = {
                pathInfos = {
                  path = "${config.users.users.${username}.home}/media/movies";
                };
              };
            }
            {
              name = "Shows";
              collectionType = "tvshows";
              libraryOptions = {
                pathInfos = {
                  path = "${config.users.users.${username}.home}/media/shows";
                };
              };
            }
          ];
        };
        startup = {
          completeStartupWizard = true;
        };
        users = [
          {
            name = "${username}";
            passwordFile = config.sops.secrets."users/${username}/jellyfin_admin-${hostname}".path;
            policy = {
              isAdministrator = true;
              loginAttemptsBeforeLogout = 3;
            };
          }
        ];
      };
    };
  };
}
