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

  # jellyfin-web: ${pkgs.jellyfin-web}/share/jellyfin-web/config.json
  # jellyfin: system.xml in the configDir (see below)
  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      configDir = "${home}/.config/jellyfin";
      dataDir = "${home}/.local/share/jellyfin";
      openFirewall = true;
      logDir = "${home}/.local/share/jellyfin/log";
      user = "${username}";
    };

    # prevent the service from auto-starting on boot
    systemd.services.jellyfin.wantedBy = lib.mkForce [ ];

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];
    users.users.${username} = {
      # add the jellyfin user to the render group
      extraGroups = [ "render" ];
    };
  };
}
