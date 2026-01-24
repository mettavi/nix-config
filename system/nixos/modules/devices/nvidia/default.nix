{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.devices.nvidia;
in
{
  options.mettavi.system.devices.nvidia = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure nvidia gpu devices";
    };
  };

  config = mkIf cfg.enable {

    # USERSPACE LIBRARIES FOR NVIDIA
    # Not sure if this is actually used on wayland
    # NB: AMD works out of the box
    services.xserver.videoDrivers = [
      "nvidia"
    ];

    #####################################################################
    # VAAPI and NVIDIA
    # Enable hardware video decoding (e.g., for YouTube, videos) in browsers or media players on Linux.

    # VA-API implemention using NVIDIA's NVDEC for use with Firefox (decoding only)
    # NB: This is already enabled by default by the hardware.nvidia.videoAcceleration option (see below)
    hardware.graphics.extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];

    environment.variables = {
      # tell the VA-API library to load the NVIDIA driver
      LIBVA_DRIVER_NAME = "nvidia";
      # Select the "direct" nvidia backend for VA-API
      NVD_BACKEND = "direct";
    };
    ######################################################################

    # NB: the module below adds boot.blacklistedKernelModules = [ "nouveau" ];
    hardware.nvidia = {
      # this adds the nvidia-powerd service
      dynamicBoost.enable = true;
      # Kernel mode setting (KMS) allows native video resolution during boot and in tty's
      # On wayland, KMS is also required for the offloading mode (see below)
      # to ensure the iGPU is used as the primary display
      modesetting.enable = true;
      nvidiaSettings = true;
      # The open driver is recommended by nvidia now, see
      # https://download.nvidia.com/XFree86/Linux-x86_64/565.77/README/kernel_open.html
      # NB: The NVreg_EnableGpuFirmware option cannot be disabled on the nvidia open drivers
      open = true;
      # KERNEL MODULES FOR NVIDIA
      # use config.boot to use the module from the installed kernel
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement = {
        # this adds the nvidia-{suspend,hibernate,resume} services
        enable = true;
        # experimental power management of prime offload
        finegrained = true;
      };
      # prime sync and reverse sync modes only work on X11
      # NB: the bus ID settings are in the host-specific configuration.nix
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
      # this option adds pkgs.nvidia-vaapi-driver but no configuration (see above)
      videoAcceleration = true; # default = true
    };
  };
}
