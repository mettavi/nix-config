{
  config,
  hostname,
  lib,
  secrets_path,
  username,
  ...
}:

let
  cfg = config.mettavi.system.services.geoipupdate;
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  options.mettavi.system.services.geoipupdate = {
    enable = mkEnableOption "Set up geoipupdate using the Maxmind database";
  };

  config = mkIf cfg.enable {
    services = {
      geoipupdate = {
        enable = true;
        interval = "weekly";
        settings = {
          AccountID = 1395964;
          DatabaseDirectory = "/var/lib/GeoIP";
          EditionIDs = [
            "GeoLite2-ASN"
            "GeoLite2-City"
            "GeoLite2-Country"
          ];
          LicenseKey = config.sops.secrets."users/${username}/maxmind-license-${hostname}.key".path;
        };
      };

      sops.secrets = {
        "users/${username}/maxmind-license-${hostname}.key" = {
          sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
        };
      };
    };
  };
}
