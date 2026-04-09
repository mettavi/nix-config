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

    # KERNEL MODULES
    # modules that are ALWAYS loaded by the initrd
    boot.initrd.kernelModules = [
      # nvidia module is not needed in the initrd
      # see https://discourse.nixos.org/t/nvidia-drm-fails-to-load/69582/4
      # "nvidia"
    ];
    # kernel modules to be loaded in the second stage of the boot process
    boot.kernelModules = [
      "nvidia"
    ];

    # kernel module or builtin options to be added to /etc/modprobe.d/
    boot.extraModprobeConfig = # bash
      ''
        # options yourmodulename optionA=valueA optionB=valueB # syntax
        # Add the S0ix module parameter
        options nvidia NVreg_EnableS0ixPowerManagement=1
        # see https://wiki.nixos.org/wiki/NVIDIA re this option
        options nvidia NVreg_TemporaryFilePath=/var/tmp
      '';

    # Parameters added to the kernel command line (can only be used for built-in modules)
    boot.kernelParams = [
      # change defaults to workaround the nvidia GPU freeze-on-resume problem
      # NB: these parameters are ALSO set by some hardware.nvidia.* options (see below)
      # see https://bbs.archlinux.org/viewtopic.php?id=300676
      # "nvidia.NVreg_PreserveVideoMemoryAllocations=0"
      # allows nvidia to manage the frame buffer device (experimental status)
      # "nvidia-drm.fbdev=0"
    ];

    # USERSPACE LIBRARIES FOR NVIDIA (propietary, required for nvidia-produced kernel modules)
    # NB: For Xorg and Wayland, AMD works out of the box
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

    environment.systemPackages = with pkgs; [
      nvtopPackages.nvidia # htop-like task monitor for nvidia GPUs
    ];

    # NB: the module below adds boot.blacklistedKernelModules = [ "nouveau" ];
    hardware.nvidia = {
      # this adds the nvidia-powerd service
      dynamicBoost.enable = true;
      # Kernel mode setting (KMS) allows native video resolution during boot and in tty's
      # On wayland, KMS is also required for the offloading mode (see below)
      # to ensure the iGPU is used as the primary display
      # NB: This option will add nvidia-drm.fbdev=1 to boot.kernelParams
      modesetting.enable = true;
      # Enable the Nvidia settings GUI, accessible via `nvidia-settings`
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
        # and the option nvidia.NVreg_PreserveVideoMemoryAllocations=1 to boot.kernelParams
        enable = true;
        # experimental power management of prime offload (turns off GPU when not in use)
        # NB: this option will add NVreg_DynamicPowerManagement=0x02 to boot.kernelParams
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
