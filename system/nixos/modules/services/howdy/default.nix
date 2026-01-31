{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mettavi.system.services.howdy;
in
{
  options.mettavi.system.services.howdy = {
    enable = lib.mkEnableOption "Install and set up howdy to implement face recognition authentication";
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      v4l-utils # video for linux (v4l) library and utilities to handle video capture, including webcams
    ];
    services.howdy = {
      enable = true;
      control = "sufficient";
    };

    # enable IR emitter hardware designed to be used with the Howdy facial authentication
    services.linux-enable-ir-emitter.enable = config.services.howdy.enable;

  };
}
