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
      # vuetorrent
    ];
    xdg.configFile = {
      # link without copying to nix store (manage externally) - must use absolute paths
      # mkOutOfStoreSymlink is required to allow the lazy-lock.json file to be writable
      "qBittorrent/qBittorrent.conf".source =
        mkOutOfStoreSymlink "${inputs.self}/home/shared/modules/apps/qbittorrent/qBittorrent.conf";
    };
  };
}
