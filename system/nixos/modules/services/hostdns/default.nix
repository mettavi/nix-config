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
    services.dnsmasq = {
      enable = true;
      settings = {
        # use the wildcard feature of dnsmasq to easily configure hosts on localhost, rather than /etc/hosts
        # send *.oona to localhost, and also append .oona to single label hostnames
        address = "/oona/127.0.0.1";
        # do not bind to the wildcard of the listen-address, just the literal IP
        bind-interfaces = true;
        # listen on port 53, but bound to this custom address (to prevent conflict with resolved 127.0.0.53)
        listen-address = "127.0.0.113";
        # do not refer to /etc/resolv.conf, to prevent an infinite loop with resolved
        # NB: /etc/resolv.conf has a "stub" DNS address pointing to resolved
        no-resolv = true;
      };
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      # Code adapted from https://jiaxiaodong.com/posts/computing/server/nix/nginx-reverse-proxy
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

    environment.etc = {
      "systemd/resolved.conf.d/10_oona.conf".text = # bash
        ''
          [Resolve]
          DNS=127.0.0.113
          Domains=oona
        '';
    };
  };
}
