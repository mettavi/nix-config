{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.mettavi.apps.qbittorrent;
in
{
  options.mettavi.apps.qbittorrent = {
    enable = lib.mkEnableOption "Install and set up qbittorrent";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      qbittorrent
      # vuetorrent # WEBUI for qBittorrent made with Vuejs
    ];
    xdg.configFile = {
      # link without copying to nix store (manage externally) - must use absolute paths
      "qBittorrent/qBittorrent.conf".source =
        mkOutOfStoreSymlink "${inputs.self}/home/shared/modules/apps/qbittorrent/qBittorrent.conf";
    };
  };
}
