{
  config,
  lib,
  username,
  ...
}:
let
  cfg = config.mettavi.system.services.transmission;
  home = config.users.users.${username}.home;
in
{
  options.mettavi.system.services.transmission = {
    enable = lib.mkEnableOption "Install and set up the transmission bittorrent service";
  };

  config = lib.mkIf cfg.enable {
    services.transmission = {
      enable = true;
      home = /var/lib/transmission;
      openPeerPorts = true;
      openRPCPort = true;
      settings = {
        dht-enabled = true;
        download-dir = "${config.services.transmission.home}/Downloads";
        incomplete-dir-enabled = true;
        incomplete-dir = "${config.services.transmission.home}/.incomplete";
        peer-port = 51413;
        preferred-transports = [
          "utp"
          "tcp"
        ];
        rename-partial-files = true;
        rpc-enabled = true;
        # if required, can use https://github.com/tomwijnroks/transmission-pwgen to set up authentication
        rpc-authentication-required = false;
        rpc-bind-address = "127.0.0.1";
        rpc-port = 9091;
        rpc-url = "/transmission/";
        start-added-torrents = true; # Start torrents as soon as they are added
        torrent-added-verify-mode = "fast"; # fast or full
        torrent-complete-verify-enabled = true;
        trash-can-enabled = true; # tranmission-gtk only
        trash-original-torrent-files = true; # Delete torrents added from the watch directory
        watch-dir-enabled = true;
        watch-dir = "${config.services.transmission.home}/watchdir";
      };
    };
  };
}
