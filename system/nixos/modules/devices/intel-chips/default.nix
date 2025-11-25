{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.devices.intel-chips;
in
{
  options.mettavi.system.devices.intel-chips = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure intel cpu/gpu devices";
    };
  };

  config = mkIf cfg.enable {

    # Only set this if using intel-vaapi-driver:
    nixpkgs.config.packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    };

    hardware = {
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          # For Broadwell and newer (ca. 2014+), use with LIBVA_DRIVER_NAME=iHD:
          intel-media-driver
          # For older processors, use with LIBVA_DRIVER_NAME=i965:
          # (older but works better for Firefox/Chromium)
          intel-vaapi-driver
          libvdpau-va-gl # Video Decode and Presentation API for Unix
          intel-ocl # Generic OpenCL support
          # OpenCL support for intel CPUs before 12th gen
          # see: https://github.com/NixOS/nixpkgs/issues/356535
          intel-compute-runtime-legacy1
          # modern graphics API that provides improved performance and better control over graphics hardware
          vulkan-loader
          vulkan-tools
          # unfortunately this driver is deprecated with several security vulnerabilities
          # use vaapi drivers abover instead
          # intel-media-sdk # for Quick Sync Video (QSV) (8th-11th gen cpu)
        ];
      };
    };
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD"; # Force intel-media-driver
    };
  };
}
