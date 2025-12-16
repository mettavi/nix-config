{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.mettavi.apps.qbittorrent;
in
{
  options.mettavi.apps.qbittorrent = {
    enable = mkEnableOption "Install and set up qbittorrent";
    isService = mkEnableOption "Use the qbittorrent web GUI with a systemd service"; # use the desktop app by default (no service)
  };

  config = mkIf cfg.enable {
    # install the desktop app (no service)
    home-manager.users.${username} = mkIf (!cfg.isService) {
      home.packages = with pkgs; [
        qbittorrent
      ];
      xdg.configFile = {
        # link without copying to nix store (manage externally) - must use absolute paths
        # no documentation of config file syntax is available, so use the GUI to write to an out-of-store file
        "qBittorrent/qBittorrent.conf".source =
          mkOutOfStoreSymlink "${inputs.self}/home/shared/modules/apps/qbittorrent/qBittorrent.conf";
      };
    };
    # install the web GUI and systemd service
    services.qbittorrent = mkIf (cfg.isService) {
      enable = true;
      openFirewall = true; # open both the webuiPort and torrentPort over TCP
      packages = pkgs.qbittorent-nox;
      profileDir = "${config.users.users.${username}.home}/.config/qbittorrent"; # location of configuration files
      serverConfig = {
        LegalNotice.Accepted = true;
        Preferences = {
          General = {
            BitTorrent = {
              Session = {
                ClosetoTrayNotified = true;
                DefaultSavePath = "${config.users.users.${username}.home}/Downloads/qbittorrent/completed";
                PreventFromSuspendWhenDownloading = true;
                TempPathEnabled = true;
                TempPath = "${config.users.users.${username}.home}/Downloads/qbittorrent/incomplete";
                TorrentExportDirectory = "${config.users.users.${username}.home}/Downloads/qbittorrent/torrents";
              };
              WebUI = {
                AlternativeUIEnabled = true;
                RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
              };
            };
          };
          torrentingPort = null; # use a random outgoing port
          webuiPort = 8090;
        };
      };
    };
    environment.systemPackages = mkIf (cfg.isService) [
      pkgs.vuetorrent # WEBUI for qBittorrent made with Vuejs
    ];
  };
}
