# Code adapted from https://jiaxiaodong.com/posts/computing/server/nix/nginx-reverse-proxy
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.hostdns;
in
{
  options.mettavi.system.services.hostdns = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up friendly hostnames using resolved, dnsmasq and nginx for services running on localhost";
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts =
        let
          # Maps a list [name, port] into a config that we want
          portMap = [
            [
              "abs"
              13378
            ]
          ];
          configgen = (
            host: xs:
            let
              name = builtins.elemAt xs 0;
              port = toString (builtins.elemAt xs 1);
            in
            {
              name = "${name}.${host}";
              value = {
                locations."/".proxyPass = "http://localhost:${port}";
              };
            }
          );
        in
        # portMap is a list of lists of [name, port]
        # for each hostname, we generate the config for name.hostname
        (builtins.foldl' (x: y: x // builtins.listToAttrs (map (configgen y) portMap)) { } [
          "oona"
          "localhost"
        ]);
    };
  };
}
