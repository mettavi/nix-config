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
  cfg = config.mettavi.system.services.newt;
  baseDomain = inputs.secrets.domain.primary;
  format = pkgs.formats.yaml { };
  blueprint-file = format.generate "blueprint.yml" config.services.newt.blueprint;
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
      # upgrade newt from unstable to prevent a serialization db mismatch with pangolin
      package = inputs.nixpkgs.legacyPackages.${pkgs.system}.fosrl-newt;
      # See https://docs.pangolin.net/manage/blueprints
      # NB: These do not require the integration API to be enabled
      blueprint = {
        # proxy-resources = public-resources (alias)
        proxy-resources = {
          bookorbit = {
            name = "BookOrbit";
            enabled = true;
            full-domain = "books.${baseDomain}";
            mode = "http";
            ssl = true;
            auth = {
              sso-enabled = true;
              sso-users = [ inputs.secrets.email.personal ];
            };
            rules = [
              {
                enabled = true;
                action = "allow";
                match = "path";
                value = "/api/v1/koreader/*";
                priority = 1;
              }
              {
                enabled = true;
                action = "allow";
                match = "path";
                value = "/api/v1/opds*";
                priority = 2;
              }
            ];
            targets = [
              {
                enabled = true;
                site = "Services";
                forward-identity-headers = true;
                hostname = "127.0.0.1";
                method = "http";
                port = 3000;
                priority = 100;
                healthcheck = {
                  hostname = "127.0.0.1";
                  port = 3000;
                  path = "/";
                  scheme = "http";
                  mode = "http";
                  interval = 5;
                  unhealthy-interval = 30;
                  timeout = 5;
                  follow-redirects = true;
                  method = "GET";
                  healthy-threshold = 1;
                  unhealthy-threshold = 1;
                };
              }
            ];
          };
          # example = {
          #   name = "Vaultwarden";
          #   mode = "http";
          #   "full-domain" = "vault.${baseDomain}";
          #   targets = [
          #     {
          #       hostname = "127.0.0.1";
          #       port = config.services.vaultwarden.config.ROCKET_PORT;
          #       method = "http";
          #     }
          #   ];
          # };
        };
        private-resources = {
          syncthing-gui = {
            enabled = true;
            mode = "http";
            name = "Syncthing-GUI";
            destination = "127.0.0.1";
            destination-port = 8384;
            full-domain = "sync.${baseDomain}";
            scheme = "http";
            sites = [ "Services" ];
            ssl = true;
            # AUTHENTICATION
            # the admin role is not valid here
            roles = [ "Member" ];
            machines = [ "similar-ichthyophis-mindanaoensis" ]; # Oona machine
            users = [ inputs.secrets.email.personal ];
          };
          syncthing-sync = {
            enabled = true;
            mode = "host";
            name = "Syncthing-Sync";
            # Set a clear private DNS alias for the data stream
            alias = "data.syncthing.mettavi.cloud";
            destination = "127.0.0.1";
            disable-icmp = false;
            sites = [ "Services" ];
            tcp-ports = "22000";
            udp-ports = "22000";
            # AUTHENTICATION
            machines = [ "similar-ichthyophis-mindanaoensis" ]; # Oona machine
            users = [ inputs.secrets.email.personal ];
          };
          vaultwarden = {
            enabled = true;
            name = "Vaultwarden";
            destination = "127.0.0.1";
            destination-port = 8222;
            full-domain = "vault.${baseDomain}";
            # the admin role is not valid here
            roles = [ "Member" ];
            # Oona machine
            machines = [ "similar-ichthyophis-mindanaoensis" ];
            mode = "http";
            scheme = "http";
            sites = [ "Services" ];
            ssl = true;
            users = [ inputs.secrets.email.personal ];
          };
        };
        sites = {
          "Services" = {
            name = "Services";
            docker-socket-enabled = true;
          };
        };
      };

      # NEWT_ID and NEWT_SECRET live here, never in settings/CLI args or the Nix store
      environmentFile = config.sops.secrets."users/${username}/newt.env".path;

      settings = {
        endpoint = "https://pangolin.${baseDomain}";
        # log-level = "DEBUG";
        provisioning-blueprint-file = "${blueprint-file}";
      };
    };
  };
}
