{
  config,
  lib,
  nix_repo,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.apps.qbittorrent;
in
rec {
  options.mettavi.system.apps.qbittorrent = {
    enable = mkEnableOption "Install and set up qbittorrent";
    isService = mkEnableOption "Use the qbittorrent web GUI with a systemd service"; # use the desktop app by default (no service)
  };

  config = mkIf cfg.enable {
    # select the desktop app (no service)
    home-manager.users.${username} =
      { config, ... }:
      with lib;
      let
        inherit (config.lib.file) mkOutOfStoreSymlink;
      in
      {
        home.packages =
          with pkgs;
          mkIf (!cfg.isService) [
            qbittorrent
          ];
        xdg.configFile = mkIf (!cfg.isService) {
          # link without copying to nix store (manage externally) - must use absolute paths
          # no documentation of config file syntax is available, so use the GUI to write to an out-of-store file
          "qBittorrent" = {
            # do not fail if the backup file already exists, as it changes frequently; overwrite it instead
            source = mkOutOfStoreSymlink "${config.home.homeDirectory}/${nix_repo}/home/shared/dots/qBittorrent";
          };
        };
        xdg.mimeApps.defaultApplications = {
          "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";
          "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
        };
      };
    # select the web GUI and systemd service
    services.qbittorrent = mkIf (cfg.isService) {
      enable = true;
      openFirewall = true; # open both the webuiPort and torrentPort over TCP
      package = pkgs.qbittorent-nox;
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
