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

    # prevent the service from auto-starting on boot
    systemd.services.jellyfin.wantedBy = lib.mkForce [ ];

    environment.systemPackages = with pkgs; [
      intel-gpu-tools # testing of the Intel DRM driver
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
      libva-utils # utilities for VA-API (video acceleration API)
    ];
    users.users.${username} = {
      # add the jellyfin user to the render group
      extraGroups = [ "render" ];
    };
  };
}
