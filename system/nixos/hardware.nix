{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libvdpau-va-gl
      # modern graphics API that provides improved performance and better control over graphics hardware
      vulkan-loader
      vulkan-tools
    ];
  };
  hardware.logitech = {
    # enable support for Logitech Wireless Devices
    wireless = {
      enable = true; # installs ltunify and logitech-udev-rules packages
      enableGraphical = true; # installs solaar gui and command for extra functionality (eg. bolt connector devices)
    };
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # Force intel-media-driver
  };
}
