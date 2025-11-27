{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.mettavi.system.services.jellyfin;
  home = config.users.users.${username}.home;
in
{
  options.mettavi.system.services.jellyfin = {
    enable = lib.mkEnableOption "Install and set up the jellyfin media server";
  };

  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      configDir = "${home}/.config/jellyfin";
      dataDir = "${home}/.local/share/jellyfin";
      openFirewall = true;
      logDir = "${home}/.local/share/jellyfin/log";
      user = "${username}";
    };
    environment.systemPackages = [
      pkgs.jellyfin
      pkgs.jellyfin-web
      pkgs.jellyfin-ffmpeg
    ];
  };
}
