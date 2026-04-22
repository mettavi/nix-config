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
    networking.networkmanager = {
      enable = true;
      # one of "OFF", "ERR", "WARN", "INFO", "DEBUG", "TRACE"
      logLevel = "INFO";
    };

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

    # see man nm-settings-keyfile and man nm-settings(-cli) for available settings
    networking.networkmanager.ensureProfiles = {
      environmentFiles = [ "${config.sops.secrets."users/${username}/wifi.env".path}" ];
      profiles = {
        NEWBURY-STAFF = {
          connection = {
            autoconnect = true;
            id = "NEWBURY-STAFF";
            interface-name = "wlp99s0";
            type = "wifi";
            uuid = "e87a7616-b5a3-41da-b2a8-d6c2de0d378d";
          };
          ipv4 = {
            address1 = "192.168.1.250/24";
            dns = "192.168.1.1";
            gateway = "192.168.1.1";
            method = "manual";
            never-default = "false";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "disabled";
          };
          wifi = {
            mac-address-blacklist = "";
            mode = "infrastructure";
            ssid = "NEWBURY-STAFF";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$psk_newstaff";
          };
        };
        MV-Pix8Pro = {
          connection = {
            autoconnect = true;
            id = "MV-Pix8Pro";
            interface-name = "wlp99s0";
            type = "wifi";
            uuid = "7765e74e-3662-4d35-870b-7ffd537bba20";
          };
          ipv4 = {
            address1 = "10.113.171.25/24";
            dns = "10.113.171.135";
            gateway = "10.113.171.135";
            method = "manual";
            never-default = "false";
          };
          ipv6 = {
            addr-gen-mode = "default";
            method = "disabled";
          };
          wifi = {
            mac-address-blacklist = "";
            mode = "infrastructure";
            ssid = "MV-Pix8Pro";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$psk_mvp8pro";
          };
        };
      };
      # NB: Could not get this secrets method to work, opted to use "environmentFiles" instead (see above)
      # see https://codeberg.org/lilly/nm-file-secret-agent and search.nixos.org for details
      # secrets = {
      #   package = pkgs.nm-file-secret-agent;
      #   entries = [
      #     {
      #       file = "${config.sops.secrets."users/${username}/wifi.env".path}";
      #       key = "psk";
      #       matchId = "NEWBURY-STAFF";
      #       matchSetting = "wifi-security";
      #       matchType = "wifi";
      #     }
      #   ];
      # };
    };
  };
}
