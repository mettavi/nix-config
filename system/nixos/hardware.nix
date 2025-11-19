{ pkgs, ... }:
{
  hardware = {
    graphics = {
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
    sane = {
      # Enable support for SANE scanners
      enable = true;
      disabledDefaultBackends = [
        # prevent same scanner being found twice (once by escl, once by airscan)
        "escl"
      ];
      extraBackends = [
        # Apple AirScan and Microsoft WSD support, for driverless scanning (supports many vendors/devices)
        pkgs.sane-airscan
      ];
    };
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # Force intel-media-driver
  };
}
