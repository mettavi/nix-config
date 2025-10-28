{
  config,
  lib,
  username,
  ...
}:
{
  programs.firefox = lib.mkIf config.home-manager.users.${username}.mettavi.apps.firefox.enable {
    enable = true;
    wrapperConfig = lib.mkIf config.services.displayManager.gdm.wayland {
      # required for screensharing under Wayland, see https://wiki.nixos.org/wiki/Firefox
      pipewireSupport = true;
    };
  };
}
