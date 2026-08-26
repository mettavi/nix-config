{
  config,
  hostname,
  inputs,
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

    systemd.services = {
      pangolin-cli = {
        enable = true;
        after = [ "network.target" ];
        description = "Pangolin Machine Client Service";
        serviceConfig = {
          # Load environment variables securely at service start
          EnvironmentFile = config.sops.secrets."users/${username}/pangolin-cli-${hostname}.env".path;
          # Run in foreground (--attach) so systemd can track process state
          # ExecStart = "${pkgs.pangolin-cli}/bin/pangolin up --endpoint https://pangolin.${inputs.secrets.domain.primary} --attach";
          # Systemd performs the \${VAR} substitution dynamically at runtime!
          # This keeps your Nix store completely clean of any hardcoded secrets.
          ExecStart = "${pkgs.pangolin-cli}/bin/pangolin up --id \${CLIENT_ID} --secret \${CLIENT_SECRET} --endpoint \${PANGOLIN_ENDPOINT} --attach";
          # Apply split-DNS routing rules directly to the pangolin interface
          ExecStartPost = pkgs.writeShellScript "pangolin-split-dns" ''
            # Wait briefly for the pangolin interface to initialize
            sleep 2
            # Assign the tunnel DNS to the pangolin interface only
            ${pkgs.systemd}/bin/resolvectl dns pangolin 100.96.128.1
            # The '~' prefix defines this as a Routing Domain (only queries matching this domain go to 100.96.128.1)
            ${pkgs.systemd}/bin/resolvectl domain pangolin "~${inputs.secrets.domain.primary}"
          '';
          # Hardening measures (optional but recommended)
          ProtectSystem = "strict";
          ProtectHome = true; # Keeps /home inaccessible; /var/lib is unaffected
          Restart = "always";
          RestartSec = "5s";
          # Provide persistent state directory & set $HOME
          Environment = [
            "HOME=/var/lib/pangolin"
            "PANGOLIN_ENDPOINT=https://pangolin.${inputs.secrets.domain.primary}"
          ];
          StateDirectory = "pangolin";
          WorkingDirectory = "/var/lib/pangolin";
        };
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}
