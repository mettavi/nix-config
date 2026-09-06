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

  # see the wiki at https://github.com/qbittorrent/qBittorrent/wiki
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
    # select the web GUI and systemd service (qBittorrent-nox - "no X server")
    services.qbittorrent = mkIf (cfg.isService) {
      enable = true;
      openFirewall = true; # open both the webuiPort and torrentPort over TCP
      package = pkgs.qbittorent-nox;
      profileDir = "${config.users.users.${username}.home}/.config/qbittorrent"; # location of configuration files
      serverConfig = {
        LegalNotice.Accepted = true;
        BitTorrent = {
          Session = {
            DefaultSavePath = "${config.users.users.${username}.home}/Downloads/qbittorrent/completed";
            Port = "61131";
            TempPathEnabled = true;
            TempPath = "${config.users.users.${username}.home}/Downloads/qbittorrent/incomplete";
            TorrentExportDirectory = "${config.users.users.${username}.home}/Downloads/qbittorrent/torrents";
          };
        };
        Preferences = {
          General = {
            ClosetoTrayNotified = true;
            CustomUIThemePath = "${
              config.users.users.${username}.home
            }/${nix_repo}/system/nixos/modules/apps/qbittorrent/dracula.qbtheme";
            PreventFromSuspendWhenDownloading = true;
            UseCustomUITheme = true;
          };
          WebUI = {
            AlternativeUIEnabled = true;
            Port = "8090";
            RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
          };
        };
      };
    };
  };
  environment.systemPackages = mkIf (cfg.isService) [
    pkgs.vuetorrent # WEBUI for qBittorrent made with Vuejs
  ];
}
