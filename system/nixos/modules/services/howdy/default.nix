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

    # workaround 1 which may be superseded by the systemd.services config below
    # see https://github.com/boltgolt/howdy/issues/1016
    # security.pam.services = {
    #   polkit = {
    #     enable = true;
    #     extraConfig = ''
    #       auth sufficient pam_howdy.so
    #     '';
    #   };
    # };

    # workaround 2 for problem with authentication via polkit 127
    # see https://github.com/NixOS/nixpkgs/issues/483867
    # and https://github.com/boltgolt/howdy/issues/1077
    systemd.services."polkit-agent-helper@".serviceConfig = {
      # allow rw access to video4linux group, which includes the IR camera howdy uses
      DeviceAllow = [ "char-video4linux rw" ];
      # allow access to physical instead of only API pseudo devices
      PrivateDevices = "no";
    };

    services.howdy = {
      enable = true;
      control = "sufficient";
      settings = {
        video = {
          dark_threshold = 80;
        };
      };
    };

    # enable IR emitter hardware designed to be used with the Howdy facial authentication
    services.linux-enable-ir-emitter.enable = config.services.howdy.enable;

  };
}
