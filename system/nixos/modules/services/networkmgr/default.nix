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
    # networking.networkmanager.unmanaged = [ "wg0" ];

    # allow user to configure networking
    users.users.${username}.extraGroups = [ "networkmanager" ];

    programs = mkIf config.mettavi.system.desktops.gnome.enable {
      # a NetworkManager control applet for GNOME (includes nm-applet and nm-connection-manager)
      nm-applet.enable = true;
    };

    # set to false to configure static IP addresses declaratively
    # (less convenient if  frequently moving between different SSIDs)
    # NB: this option also requires networking.useDHCP=true
    # networking.dhcpcd.enable = true;

    # NOTE: There are apparent problems with using dhcpcd via networkmanager
    # because there is no /etc/dhcpcd.conf file unless 1) created manually or 2) via workarounds
    # see 1) https://discourse.nixos.org/t/adding-to-dhcpcd-conf/33727
    # and 2) https://github.com/NixOS/nixpkgs/issues/341092

    # one of "dhcpcd" (dhcp client daemon) or "internal"
    # networking.networkmanager.dhcp = "dhcpcd";

    networking.networkmanager.dhcp = "internal"; # internal is the default

    # Set the DNS (resolv.conf) processing mode
    # one of "default", "dnsmasq", "systemd-resolved", "none"
    # the systemd-resolved dns stub resolver listens on port 53 on IP address 127.0.0.53 by default
    networking.networkmanager.dns = "systemd-resolved";
    services.resolved.enable = true;

    networking.networkmanager.wifi = {
      # wpa_supplicant or iwd (experimental)
      backend = "wpa_supplicant";
    };

    # network definitions to automatically connect to when wpa_supplicant is running.
    # If this parameter is left empty wpa_supplicant will use /etc/wpa_supplicant.conf as the configuration file.
    # networking.wireless.networks = {
    # secretsFile = "${config.sops.secrets."users/${username}/wifi.env".path}";
    # "MV-Pix8Pro" = {
    # read PSKs from the variable ext:<variable>, defined in secretsFile
    #   pskRaw = "ext:psk_mvp8pro";
    # };
    #   "NEWBURY-STAFF" = {
    #     pskRaw = "ext:psk_newstaff";
    #   };
    # };
  };
}
