{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.networkmanager;
in
{
  options.mettavi.system.services.networkmanager = {
    enable = lib.mkEnableOption "Enable and setup the networkmanager networking backend";
  };
  config = mkIf cfg.enable {

    # Configure network connections interactively with nmcli or nmtui.
    networking.networkmanager.enable = true;

    # List of interfaces that will not be managed by NetworkManager
    networking.networkmanager.unmanaged = [ "wg0" ];

    # allow user to configure networking
    users.users.${username}.extraGroups = [ "networkmanager" ];

    programs = mkIf config.mettavi.system.gnome.enable {
      # a NetworkManager control applet for GNOME (includes nm-applet and nm-connection-manager)
      nm-applet.enable = true;
    };

    # set to false to configure static IP addresses declaratively
    # ( less convenient if  frequently moving between different SSIDs)
    networking.dhcpcd.enable = true;
    # one of "dhcpcd" (dhcp client daemon) or "internal"
    networking.networkmanager.dhcp = "dhcpcd";

    # Set the DNS (resolv.conf) processing mode
    # one of "default", "dnsmasq", "systemd-resolved", "none"
    networking.networkmanager.dns = "systemd-resolved";

    networking.networkmanager.wifi = {
      # wpa_supplicant or iwd (experimental)
      backend = "wpa_supplicant";
    };

    # network definitions to automatically connect to when wpa_supplicant is running.
    # If this parameter is left empty wpa_supplicant will use /etc/wpa_supplicant.conf as the configuration file.
    networking.wireless.networks = {
      secretsFile = config.sops.secrets."wifi.env".path;
      "MV-Pix8Pro" = {
        # read PSKs from the variable ext:<variable>, defined in secretsFile
        pskRaw = "ext:psk_mvp8pro";
      };
      "NEWBURY-STAFF" = {
        pskRaw = "ext:psk_newstaff";
      };
    };
  };
}
