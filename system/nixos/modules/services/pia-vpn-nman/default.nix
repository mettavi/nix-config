# original code borrowed from https://github.com/rcambrj/nix-pia-vpn
{
  config,
  lib,
  nix_repo,
  pkgs,
  username,
  ...
}:
let
  cfg = config.mettavi.system.services.pia-vpn-netmanager;
in
with lib;

{
  options.mettavi.system.services.pia-vpn-netmanager = {
    enable = mkEnableOption "Private Internet Access VPN service.";

    certificateFile = mkOption {
      type = types.path;
      default = ./ca.rsa.4096.crt;
      description = ''
        Path to the CA certificate for Private Internet Access servers.

        This is provided as <filename>ca.rsa.4096.crt</filename>, 
        available from https://github.com/pia-foss/manual-connections.
      '';
    };

    environmentFile = mkOption {
      type = types.path;
      description = ''
        Path to an environment file with the following contents:

        <programlisting>
        PIA_USER=''${username}
        PIA_PASS=''${password}
        </programlisting>
      '';
    };

    interface = mkOption {
      type = types.str;
      default = "wg0";
      description = ''
        WireGuard interface to create for the VPN connection.
      '';
    };

    region = mkOption {
      type = types.str;
      default = "";
      description = ''
        Name of the region to connect to.
        See https://serverlist.piaservers.net/vpninfo/servers/v4
      '';
    };

    maxLatency = mkOption {
      type = types.float;
      default = 0.1;
      description = ''
        Maximum latency to allow for auto-selection of VPN server,
        in seconds. Does nothing if region is specified.
      '';
    };

    networkManConfig = mkOption {
      type = types.str;
      default = # bash
        ''
          # Networkmanager config for the PIA wireguard VPN service
          [Interface]
          # IP on the wireguard network
          Address = ''${peerip}/32
          PrivateKey = $privateKey 

          [Peer]
          PublicKey = $(echo "$json" | jq -r '.server_key')
          # restrict this to the wireguard subnet if you don't want to route everything to the tunnel
          AllowedIPs = 0.0.0.0/0, ::/0
          # ip and port of the peer
          Endpoint = ''${wg_ip}:$(echo "$json" | jq -r '.server_port')
          # how often to send an authenticated empty packet to the peer, 
          # for the purpose of keeping a stateful firewall or NAT mapping valid persistently
          PersistentKeepalive = 25
        '';
    };

    preUp = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands called at the start of the interface setup.
      '';
    };

    postUp = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands called at the end of the interface setup.
      '';
    };

    preDown = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands called before the interface is taken down.
      '';
    };

    postDown = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands called after the interface is taken down.
      '';
    };

    portForward = {
      enable = mkEnableOption "port forwarding through the PIA VPN connection.";

      script = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Script to execute, with <varname>$port</varname> set to the forwarded port.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    mettavi.system.services.pia-vpn-netmanager = {
      # authenticate with
      environmentFile = "${config.home-manager.users.${username}.sops.secrets."users/${username}/pia.env".path
      }";
    };

    boot.kernelModules = [ "wireguard" ];

    # If you intend to route all your traffic through the wireguard tunnel,
    # the default configuration of the NixOS firewall will block the traffic because of rpfilter
    # true (or “strict”), “loose” (only drop the packet if the source address is not reachable via any interface) or false
    networking.firewall.checkReversePath = "loose";

    # open the firewall for the default wireguard port
    networking.firewall.allowedUDPPorts = [ 51820 ];

    # Wireguard network manager
    # services.wg-netmanager.enable = true;

    systemd.services.pia-vpn = {
      description = "Connect to Private Internet Access on ${cfg.interface}";
      path = with pkgs; [
        bash
        curl
        gawk
        jq
        wireguard-tools
      ];
      requires = [ "network-online.target" ];
      after = [
        "network.target"
        "network-online.target"
      ];
      # do not start the service on system boot
      # wantedBy = [ "multi-user.target" ];

      unitConfig = {
        ConditionFileNotEmpty = [
          cfg.certificateFile
          cfg.environmentFile
        ];
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        EnvironmentFile = cfg.environmentFile;

        CacheDirectory = "pia-vpn";
        StateDirectory = "pia-vpn";
      };

      script = ''
        printServerLatency() {
          serverIP="$1"
          regionID="$2"
          regionName="$(echo ''${@:3} |
            sed 's/ false//' | sed 's/true/(geo)/')"
          time=$(LC_NUMERIC=en_US.utf8 curl -o /dev/null -s \
            --connect-timeout ${toString cfg.maxLatency} \
            --write-out "%{time_connect}" \
            http://$serverIP:443)
          if [ $? -eq 0 ]; then
            >&2 echo Got latency ''${time}s for region: $regionName
            echo $time $regionID $serverIP
          fi
        }
        export -f printServerLatency

        echo Fetching regions...
        serverlist='https://serverlist.piaservers.net/vpninfo/servers/v4'
        allregions=$((curl --no-progress-meter -m 5 "$serverlist" || true) | head -1)

        region="$(echo $allregions |
                    jq --arg REGION_ID "${cfg.region}" -r '.regions[] | select(.id==$REGION_ID)')"
        if [ -z "''${region}" ]; then
          echo Determining region...
          filtered="$(echo $allregions | jq -r '.regions[]
                    ${optionalString cfg.portForward.enable "| select(.port_forward==true)"}
                    | .servers.meta[0].ip+" "+.id+" "+.name+" "+(.geo|tostring)')"
          best="$(echo "$filtered" | xargs -I{} bash -c 'printServerLatency {}' |
                  sort | head -1 | awk '{ print $2 }')"
          if [ -z "$best" ]; then
            >&2 echo "No region found with latency under ${toString cfg.maxLatency} s. Stopping."
            exit 1
          fi
          region="$(echo $allregions |
                    jq --arg REGION_ID "$best" -r '.regions[] | select(.id==$REGION_ID)')"
        fi
        echo Using region $(echo $region | jq -r '.id')

        meta_ip="$(echo $region | jq -r '.servers.meta[0].ip')"
        meta_hostname="$(echo $region | jq -r '.servers.meta[0].cn')"
        wg_ip="$(echo $region | jq -r '.servers.wg[0].ip')"
        wg_hostname="$(echo $region | jq -r '.servers.wg[0].cn')"
        echo "$region" > $STATE_DIRECTORY/region.json

        echo Fetching token from $meta_ip...
        tokenResponse="$(curl --no-progress-meter -m 5 \
          -u "$PIA_USER:$PIA_PASS" \
          --connect-to "$meta_hostname::$meta_ip" \
          --cacert "${cfg.certificateFile}" \
          "https://$meta_hostname/authv3/generateToken" || true)"
        if [ "$(echo "$tokenResponse" | jq -r '.status' || true)" != "OK" ]; then
          >&2 echo "Failed to generate token. Stopping."
          exit 1
        fi
        token="$(echo "$tokenResponse" | jq -r '.token')"

        echo Connecting to the PIA WireGuard API on $wg_ip...
        privateKey="$(wg genkey)"
        publicKey="$(echo "$privateKey" | wg pubkey)"
        json="$(curl --no-progress-meter -m 5 -G \
          --connect-to "$wg_hostname::$wg_ip:" \
          --cacert "${cfg.certificateFile}" \
          --data-urlencode "pt=''${token}" \
          --data-urlencode "pubkey=$publicKey" \
          "https://''${wg_hostname}:1337/addKey" || true)"
        status="$(echo "$json" | jq -r '.status' || true)"
        if [ "$status" != "OK" ]; then
          >&2 echo "Server did not return OK. Stopping."
          >&2 echo "$json"
          exit 1
        fi

        echo Creating network interface ${cfg.interface}.
        echo "$json" > $STATE_DIRECTORY/wireguard.json

        gateway="$(echo "$json" | jq -r '.server_ip')"
        servervip="$(echo "$json" | jq -r '.server_vip')"
        peerip=$(echo "$json" | jq -r '.peer_ip')

        interface="${cfg.interface}"

        # save the wireguard config to the module's directory
        nixrepo="${
          config.users.users.${username}.home
        }/${nix_repo}/system/nixos/modules/services/pia-vpn-nman/wg0.conf"

        cat > $nixrepo <<EOF
        ${cfg.networkManConfig}
        EOF

        ${pkgs.networkmanager}/bin/nmcli connection import type wireguard file ./wg0.conf 
        # ${pkgs.networkmanager}/bin/nmcli modify ${cfg.interface} ipv4.route-table 42 ipv6.route-table 42
        # the main table has priority 32766
        # ${pkgs.networkmanager}/bin/nmcli connection modify ${cfg.interface} ipv4.routing-rules "priority 1000 from all table 42" ipv6.routing-rules "priority 1000 from all table 42"
        ${pkgs.networkmanager}/bin/nmcli connection modify ${cfg.interface} connection.autoconnect no

        # ===================================================================
        echo Bringing up network interface ${cfg.interface}.

        ${cfg.preUp}

        ${pkgs.networkmanager}/bin/nmcli connection reload
        ${pkgs.networkmanager}/bin/nmcli connection up ${cfg.interface} 

        # ===================================================================

        ${cfg.postUp}
      '';

      preStop = ''
        echo Removing network interface ${cfg.interface}.

        interface="${cfg.interface}"

        ${cfg.preDown}

        echo Bringing down network interface ${cfg.interface}.

        ${pkgs.networkmanager}/bin/nmcli connection down ${cfg.interface} 
        ${pkgs.networkmanager}/bin/nmcli connection delete id ${cfg.interface} 
        ${pkgs.networkmanager}/bin/nmcli connection reload

        ${cfg.postDown}
      '';
    };

    systemd.services.pia-vpn-portforward = mkIf cfg.portForward.enable {
      description = "Configure port-forwarding for PIA connection ${cfg.interface}";
      path = with pkgs; [
        curl
        jq
      ];
      after = [ "pia-vpn.service" ];
      bindsTo = [ "pia-vpn.service" ];
      wantedBy = [ "pia-vpn.service" ];

      unitConfig = {
        ConditionFileNotEmpty = [
          cfg.certificateFile
          cfg.environmentFile
        ];
      };

      serviceConfig = {
        Type = "notify";
        Restart = "always";
        CacheDirectory = "pia-vpn";
        StateDirectory = "pia-vpn";
        RestartSec = "10s";
        RestartSteps = "10";
        RestartMaxDelaySec = "15min";
        EnvironmentFile = cfg.environmentFile;
      };

      script = ''
        if [ ! -f $STATE_DIRECTORY/region.json ]; then
          echo "Region information not found; is pia-vpn.service running?" >&2
          exit 1
        fi
        region="$(cat $STATE_DIRECTORY/region.json)"

        if [ ! -f $STATE_DIRECTORY/wireguard.json ]; then
          echo "Connection information not found; is pia-vpn.service running?" >&2
          exit 1
        fi
        wg="$(cat $STATE_DIRECTORY/wireguard.json)"

        meta_ip="$(echo $region | jq -r '.servers.meta[0].ip')"
        meta_hostname="$(echo $region | jq -r '.servers.meta[0].cn')"
        wg_ip="$(echo $region | jq -r '.servers.wg[0].ip')"
        wg_hostname="$(echo $region | jq -r '.servers.wg[0].cn')"
        gateway="$(echo $wg | jq -r '.server_vip')"

        echo Fetching token from $meta_ip...
        tokenResponse="$(curl --no-progress-meter -m 5 \
          -u "$PIA_USER:$PIA_PASS" \
          --connect-to "$meta_hostname::$meta_ip" \
          --cacert "${cfg.certificateFile}" \
          "https://$meta_hostname/authv3/generateToken" || true)"
        if [ "$(echo "$tokenResponse" | jq -r '.status' || true)" != "OK" ]; then
          >&2 echo "Failed to generate token. Stopping."
          exit 1
        fi
        token="$(echo "$tokenResponse" | jq -r '.token')"

        echo "Fetching port forwarding configuration from $gateway..."
        pfconfig="$(curl --no-progress-meter -m 5 \
          --interface ${cfg.interface} \
          --connect-to "$wg_hostname::$gateway:" \
          --cacert "${cfg.certificateFile}" \
          -G --data-urlencode "token=''${token}" \
          "https://''${wg_hostname}:19999/getSignature" || true)"
        if [ "$(echo "$pfconfig" | jq -r '.status' || true)" != "OK" ]; then
          echo "Port forwarding configuration does not contain an OK status. Stopping." >&2
          exit 1
        fi

        if [ -z "$pfconfig" ]; then
          echo "Did not obtain port forwarding configuration. Stopping." >&2
          exit 1
        fi

        signature="$(echo "$pfconfig" | jq -r '.signature')"
        payload="$(echo "$pfconfig" | jq -r '.payload')"
        port="$(echo "$payload" | base64 -d | jq -r '.port')"
        expires="$(echo "$payload" | base64 -d | jq -r '.expires_at')"

        echo "Port forwarding configuration acquired: port $port expires at $(date --date "$expires")."

        systemd-notify --ready

        echo "Enabling port forwarding..."

        while true; do
          response="$(curl --no-progress-meter -m 5 -G \
            --interface ${cfg.interface} \
            --connect-to "$wg_hostname::$gateway:" \
            --cacert "${cfg.certificateFile}" \
            --data-urlencode "payload=''${payload}" \
            --data-urlencode "signature=''${signature}" \
            "https://''${wg_hostname}:19999/bindPort" || true)"
          if [ "$(echo "$response" | jq -r '.status' || true)" != "OK" ]; then
            echo "Failed to bind port. Stopping." >&2
            exit 1
          fi
          echo "Bound port $port. Forwarding will expire at $(date --date="$expires")."
          ${cfg.portForward.script}
          sleep 900
          echo "Checking port forwarding..."
        done
      '';
    };
  };
}
