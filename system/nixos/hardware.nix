{ pkgs, ... }:
{
  hardware = {
    graphics = {
      # enables the the mesa graphics library, which includes openGL, vulkan (general graphics support) drivers
      # and VA-API, VDPAU (video acceleration) drivers
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        # modern graphics API with wide compatibility providing improved performance and better control over graphics hardware
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

  # A system daemon to allow session software to update firmware
  services.fwupd.enable = true;

  # handles input devices (mouse, touchpad)
  services.libinput = {
    enable = true;
    # Disable input method while typing (default:false)
    touchpad.disableWhileTyping = true;
  };

  services.udev.packages = [
    # enable programs to pick up the above scanners
    pkgs.sane-airscan
  ];
}
