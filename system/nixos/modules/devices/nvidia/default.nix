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

    # this is a misnomer as it applies to both x11 and wayland
    # NB: AMD works out of the box
    services.xserver.videoDrivers = [
      "nvidia"
    ];

    #####################################################################
    # VAAPI and NVIDIA
    # Enable hardware video decoding (e.g., for YouTube, videos) in browsers or media players on Linux.

    # VA-API implemention using NVIDIA's NVDEC for use with Firefox (decoding only)
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

    hardware.nvidia = {
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
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
    };
  };
}
