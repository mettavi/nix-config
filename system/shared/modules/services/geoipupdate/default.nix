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
    optionalString
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
        # See https://github.com/maxmind/geoipupdate/blob/main/doc/GeoIP.conf.md for available options
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

      systemd.tmpfiles.rules = [
        # Shared directories: Geo-IP-Update (a separate system service) writes here;
        # Pangolin (rootless podman, running as `username`) reads from here;
        # Kept outside the home directory so permissions aren't blocked by a
        # 0700 $HOME.
        optionalString
        config.mettavi.system.services.pangolin.enable
        "d /var/lib/GeoIP 0750 root ${username} -"
      ];

    };
  };
}
