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
  cfg = config.mettavi.system.services.pangolin-cli;
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.mettavi.system.services.pangolin-cli = {
    enable = mkEnableOption "Install and configure the pangolin-cli client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pangolin-cli # Pangolin cli tool and VPS client
    ];

    sops.secrets."users/${username}/pangolin-cli-${hostname}.env" = {
      # Optional: specify path or restart systemd service on secret change
      restartUnits = [ "pangolin-cli.service" ];
      sopsFile = "${secrets_path}/secrets/apps/pangolin.yaml";
    };

    systemd.user.services = {
      pangolin-cli = {
        enable = true;
        after = [ "network.target" ];
        description = "Pangolin Machine Client Service";
        path = with pkgs; [ pangolin-cli ];
        serviceConfig = {
          # Load environment variables securely at service start
          EnvironmentFile = config.sops.secrets."users/${username}/pangolin-cli-${hostname}.env".path;
          # Run in foreground (--attach) so systemd can track process state
          ExecStart = "${pkgs.pangolin-cli}/bin/pangolin up --endpoint \"https://pangolin.${inputs.secrets.domain.primary}\" --attach";
          # Hardening measures (optional but recommended)
          ProtectSystem = "full";
          ProtectHome = true;
          Restart = "always";
          RestartSec = "5s";
        };
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}
