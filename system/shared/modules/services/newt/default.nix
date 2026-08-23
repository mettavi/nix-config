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
  cfg = config.mettavi.system.services.newt;
in
{
  options.mettavi.system.services.newt = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and set up the Newt tunnel client connecting this host to Pangolin";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."users/${username}/newt.env" = {
      sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
    };

    services.newt = {
      enable = true;
      # See https://docs.pangolin.net/manage/blueprints
      # blueprint = {
      #   "public-resources" = {
      #     vaultwarden = {
      #       name = "Vaultwarden";
      #       mode = "http";
      #       "full-domain" = "vault.mettavi.cloud";
      #       targets = [
      #         {
      #           hostname = "127.0.0.1";
      #           port = config.services.vaultwarden.config.ROCKET_PORT;
      #           method = "http";
      #         }
      #       ];
      #     };
      #   };
      # };

      # NEWT_ID and NEWT_SECRET live here, never in settings/CLI args or the Nix store
      environmentFile = config.sops.secrets."users/${username}/newt.env".path;

      settings = {
        endpoint = "https://pangolin.mettavi.cloud";
      };
    };
  };
}
