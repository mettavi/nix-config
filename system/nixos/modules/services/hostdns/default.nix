{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.hostdns;
  # The name of the dummy network interface used to give systemd-resolved
  # a non-loopback "link" to attach a dedicated DNS scope to. Kept under
  # 15 characters (the Linux interface-name limit) by construction, since
  # `domain` is expected to be short.
  dummyIface = "${cfg.domain}0";
in
{
  options.mettavi.system.services.hostdns = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up friendly hostnames using resolved, dnsmasq and nginx for services running on localhost";
    };

    # NEW: a single source of truth for the "domain" used everywhere in this
    # module (dnsmasq wildcard, nginx virtual host suffix, and the DNS scope
    # routing domain). Previously "oona" was hardcoded in three separate
    # places; centralizing it here means renaming only requires changing
    # this one option.
    domain = mkOption {
      type = types.strMatching "[a-z0-9-]+"; # keep it simple: lowercase, digits, hyphens
      default = "oona";
      description = "Local top-level domain used for friendly service hostnames, e.g. '<name>.<domain>'";
    };
  };

  config = mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;
      settings = {
        # Wildcard: any query for *.<domain> (and the bare "<domain>" itself)
        # gets answered with 127.0.0.1, without needing entries in /etc/hosts.
        address = "/${cfg.domain}/127.0.0.1";
        # Only listen on the specific address below, not on every interface
        # (avoids accidentally serving DNS to other networks/interfaces).
        bind-interfaces = true;
        # Deliberately NOT 127.0.0.53 (systemd-resolved's own stub address)
        # or the default port-53-on-everything — this keeps dnsmasq fully
        # separate from resolved, avoiding a port clash or resolution loop.
        listen-address = "127.0.0.113";
        # Don't consult /etc/resolv.conf for upstream servers. That file
        # points at resolved's stub resolver, so without this, dnsmasq could
        # end up asking resolved, which (via our routing) could end up
        # asking dnsmasq again — an infinite loop.
        no-resolv = true;
      };
    };

    services.nginx = {
      enable = true;
      # see https://github.com/paperless-ngx/paperless-ngx/discussions/11159
      proxyTimeout = "600m";
      recommendedProxySettings = true;
      commonHttpConfig = ''
        client_header_buffer_size 64k;
        large_client_header_buffers 4 64k;
      '';
      # Code adapted from https://jiaxiaodong.com/posts/computing/server/nix/nginx-reverse-proxy
      virtualHosts =
        let
          # Maps a list [name, port] into a config that we want
          portMap = [
            [
              "abs"
              13378
            ] # audiobookshelf
            [
              "gw"
              5000
            ] # gramps-web
            [
              "imm"
              2283
            ] # immich
            [
              "jf"
              8096
            ] # jellyfin
            [
              "pp"
              28981
            ] # paperless-personal
            [
              "ppg"
              28982
            ] # paperless-genealogy
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
                locations."/" = {
                  proxyPass = "http://localhost:${port}";
                  # required for audiobookshelf
                  proxyWebsockets = true;
                  extraConfig = ''
                    proxy_buffer_size          128k;
                    proxy_buffers              4 256k;
                    proxy_busy_buffers_size    256k;
                  '';
                };
              };
            }
          );
        in
        # For each host suffix (both the friendly domain and "localhost"),
        # generate a virtual host block per service in portMap, so both
        # "pp.oona" and "pp.localhost" work.
        (builtins.foldl' (x: y: x // builtins.listToAttrs (map (configgen y) portMap)) { } [
          cfg.domain
          "localhost"
        ]);
    };

    # Tell NetworkManager to ignore our dummy interface entirely — otherwise
    # it might try to bring it under its own management (assign addresses
    # via DHCP, show it in nmcli, etc.), which we don't want since it's
    # purely an internal plumbing device for DNS scoping.
    networking.networkmanager.unmanaged = [ "interface-name:${dummyIface}" ];

    # WHY THIS SERVICE EXISTS:
    # systemd-resolved routes DNS queries per "scope" (roughly: per network
    # link). If we add our local resolver (127.0.0.113) to the *global*
    # scope alongside real upstream DNS servers (e.g. 1.1.1.1, 8.8.8.8),
    # queries for our fake ".oona" domain can get answered by the wrong
    # server (returning NXDOMAIN instead of falling through to dnsmasq).
    # The fix is to give our local resolver its OWN dedicated scope, tied
    # to a link that exists only for this purpose. That link can't be "lo"
    # (resolved explicitly refuses per-link DNS config on loopback), so we
    # create a small dummy interface instead and attach the scope to that.
    systemd.services."${cfg.domain}-dns-scope" = {
      description = "Bind .${cfg.domain} domain resolution to a dedicated dummy-interface DNS scope";
      after = [
        "systemd-resolved.service"
        "dnsmasq.service"
        "NetworkManager.service"
      ];
      wants = [
        "systemd-resolved.service"
        "dnsmasq.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        # "oneshot" + RemainAfterExit: this isn't a long-running daemon —
        # it runs once at boot to set things up, then systemd considers the
        # service "active" without any process still running.
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = pkgs.writeShellScript "oona-dns-scope-start" ''
          set -eu

          # Create the dummy interface if it doesn't already exist (idempotent,
          # in case the service is restarted without a reboot).
          ${lib.getExe' pkgs.iproute2 "ip"} link show ${dummyIface} >/dev/null 2>&1 || \
            ${lib.getExe' pkgs.iproute2 "ip"} link add ${dummyIface} type dummy
          ${lib.getExe' pkgs.iproute2 "ip"} link set ${dummyIface} up

          # systemd-resolved only activates a DNS scope on links that have a
          # usable IP address — a dummy link with no address gets "Current
          # Scopes: none" even after DNS/domain config is applied. We don't
          # need this address to route real traffic anywhere, so we use an
          # IPv4 link-local address (169.254.0.0/16), which exists exactly
          # for "local only, no real routing needed" cases like this.
          ${lib.getExe' pkgs.iproute2 "ip"} addr add 169.254.100.1/32 dev ${dummyIface} 2>/dev/null || true

          # Look up the kernel's numeric interface index — the D-Bus calls
          # below need this rather than the interface name.
          ifindex=$(cat /sys/class/net/${dummyIface}/ifindex)

          # These two D-Bus calls are what `resolvectl dns <iface> ...` and
          # `resolvectl domain <iface> ...` do under the hood. We can't use
          # resolvectl directly here because that tool only works for links
          # managed by systemd-networkd, which isn't running on this system
          # (NetworkManager is used instead). So we call resolved's own
          # D-Bus API directly with busctl, the same way NetworkManager does.

          # SetLinkDNS: assign 127.0.0.113 as the DNS server for this link's
          # scope. Signature "ia(iay)": ifindex, then an array of (address
          # family, address bytes) — 2 = AF_INET, followed by the four
          # octets of 127.0.0.113.
          ${lib.getExe' pkgs.systemd "busctl"} call org.freedesktop.resolve1 /org/freedesktop/resolve1 \
            org.freedesktop.resolve1.Manager SetLinkDNS "ia(iay)" \
            "$ifindex" 1 2 4 127 0 0 113

          # SetLinkDomains: route queries for *.${cfg.domain} to this link's
          # scope. Signature "ia(sb)": ifindex, then an array of (domain
          # name, "routing-only" boolean). "true" here is the equivalent of
          # prefixing the domain with "~" in resolvectl — it means "route
          # matching queries here" rather than "use as a DNS search suffix".
          ${lib.getExe' pkgs.systemd "busctl"} call org.freedesktop.resolve1 /org/freedesktop/resolve1 \
            org.freedesktop.resolve1.Manager SetLinkDomains "ia(sb)" \
            "$ifindex" 1 "${cfg.domain}" true
        '';

        # Clean up on stop/reboot by simply deleting the interface — this
        # also removes the address and DNS scope config that were attached
        # to it, so there's nothing else to unwind separately.
        ExecStop = pkgs.writeShellScript "oona-dns-scope-stop" ''
          ${lib.getExe' pkgs.iproute2 "ip"} link delete ${dummyIface} || true
        '';
      };
    };
  };
}
