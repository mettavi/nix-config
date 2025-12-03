{ config, lib, ... }:
let
  cfg = config.mettavi.system.services.networkd;
in
{
  options.mettavi.system.services.networkd = {
    enable = lib.mkEnableOption "Enable the systemd-networkd framework and configure the network using its declarative options";
  };
  config = lib.mkIf cfg.enable {
    # enable networkd
    systemd.network.enable = true;

    # set to false to configure static IP addresses declaratively
    # ( less convenient if  frequently moving between different SSIDs)
    networking.dhcpcd.enable = true; # DHCP client daemon

    # Whether to enable wpa_supplicant to manage wifi (iwd is another option)
    networking.wireless.enable = true;

    # network definitions to automatically connect to when wpa_supplicant is running.
    # If this parameter is left empty wpa_supplicant will use /etc/wpa_supplicant.conf as the configuration file.
    networking.wireless.networks = {
      secretsFile = config.sops.secrets."wifi.env".path;
      "NEWBURY-STAFF" = {
        # read PSK from the variable password, defined in secretsFile
        pskRaw = "ext:psk_newstaff";
      };
    };

    systemd.network.networks."10-lan-wifi" = {
      matchConfig.Name = "wlp229s0";
      # Each attribute specifies an option in the [Network] section of the unit
      networkConfig = {
        # start a DHCP Client for IPv4 Addressing/Routing
        DHCP = "ipv4";
        # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
        IPv6AcceptRA = true;
      };
      # Each attribute specifies an option in the [Link] section of the unit
      linkConfig = {
        # make the routes on this interface a dependency for network-online.target
        RequiredForOnline = "routable";
      };
    };
  };
}
