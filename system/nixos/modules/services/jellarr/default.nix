{
  config,
  hostname,
  inputs,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.jellarr;
  home = config.users.users.${username}.home;
in
{
  # import the nixos jellarr module
  imports = [
    inputs.jellarr.nixosModules.default
  ];

  options.mettavi.system.services.jellarr = {
    enable = mkEnableOption "Install and declaratively configure the jellyfin media server using the jellarr third-party flake";
  };

  config = mkIf cfg.enable {
    # install and setup the jellyfin service
    mettavi.system.services.jellyfin.enable = true;

    # prevent the service from auto-starting on boot
    # systemd.services.jellarr.wantedBy = lib.mkForce [ ];

    # define secrets for jellarr using sops-nix module
    sops = {
      secrets = {
        "users/${username}/jellarr_apikey" = { };
      };
      templates = {
        "jellarr.env" = {
          content = ''
            JELLARR_API_KEY=${config.sops.placeholder."users/${username}/jellarr_apikey"}
          '';
          owner = config.services.jellarr.user;
          group = config.services.jellarr.group;
        };
      };
    };

    # configure the jellarr module
    services.jellarr = {
      enable = true;
      # Bootstrap: automatically inserts API key into Jellyfin's database
      # NB: bootstrap only works if jellarr and jellyfin are on the same host
      bootstrap = {
        # this option runs on reboot/nixos rebuild and then forces the jellyfin service to run
        # disable this option to start jellyfin manually
        enable = false;
        apiKeyFile = config.sops.secrets."users/${username}/jellarr_apikey".path;
      };
      dataDir = "${home}/.local/share/jellarr";
      # not required if using the bootstrap option
      # BUT: set JELLARR_API_KEY to get bootstrap option to work due to https://github.com/venkyr77/jellarr/issues/30
      environmentFile = config.sops.templates."jellarr.env".path;
      user = "${username}";
      group = "jellyfin";
      # Run interval for the timer (default: "daily")
      schedule = "daily";
      config = {
        version = 1;
        base_url = "http://localhost:8096";
        system = {
          # Enable Prometheus metrics endpoint at /metrics
          # turned off by default to avoid leaking information publicly
          enableMetrics = false;
          pluginRepositories = [
            {
              name = "Jellyfin Stable";
              url = "https://repo.jellyfin.org/releases/plugin/manifest.json";
              enabled = true;
            }
          ];
          trickplayOptions = {
            enableHwAcceleration = true;
            enableHwEncoding = true;
          };
        };
        branding = {
          splashscreenEnabled = false;
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
          allowHevcEncoding = true;
          allowAv1Encoding = false;
        };
        library = {
          virtualFolders = [
            {
              name = "Movies";
              collectionType = "movies";
              libraryOptions = {
                pathInfos = [
                  {
                    path = "${config.users.users.${username}.home}/media/movies";
                  }
                ];
              };
            }
            {
              name = "Shows";
              collectionType = "tvshows";
              libraryOptions = {
                pathInfos = [
                  {
                    path = "${config.users.users.${username}.home}/media/shows";
                  }
                ];
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
            passwordFile =
              optionalString config.mettavi.system.services.jellyfin.set_signin
                config.sops.secrets."users/${username}/jellyfin_admin-${hostname}".path;
            policy = {
              isAdministrator = true;
              loginAttemptsBeforeLockout = 3;
            };
          }
        ];
      };
    };
  };
}
