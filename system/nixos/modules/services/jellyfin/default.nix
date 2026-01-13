{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.jellyfin;
  home = config.users.users.${username}.home;
  hostname = config.networking.hostName;
in
{
  options.mettavi.system.services.jellyfin = {
    enable = mkEnableOption "Install and set up the jellyfin media server";
    set_signin = mkEnableOption "Preconfigure signin credentials using the sops-nix secrets module";
  };

  # jellyfin-web: ${pkgs.jellyfin-web}/share/jellyfin-web/config.json
  # jellyfin: system.xml in the configDir (see below)
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    services.jellyfin = {
      enable = true;
      configDir = "${home}/.config/jellyfin";
      dataDir = "${home}/.local/share/jellyfin";
      openFirewall = true;
      logDir = "${home}/.local/share/jellyfin/log";
      user = "${username}";
    };

    sops.secrets = mkIf cfg.set_signin {
      "users/${username}/jellyfin_admin-${hostname}" = { };
    };

    # prevent the service from auto-starting on boot
    systemd.services.jellyfin.wantedBy = mkForce [ ];

    users.users.${username} = {
      # add the jellyfin user to the render group
      extraGroups = [ "render" ];
    };
  };
}
