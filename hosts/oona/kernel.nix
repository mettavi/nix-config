{ pkgs, ... }:
{
  # override the Linux kernel (and hence its kernel modules) used by NixOS
  # Use the cachyos kernel for the latest asus g14 kernel patches (using custom flake input and overlay)
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest; # default pkgs.linuxPackages

  ###### KERNEL MODULES ######
  # modules available in the initrd, BUT ONLY LOADED ON DEMAND
  boot.initrd.availableKernelModules = [
    "usb_storage"
    "sd_mod"
    # copied from the hardware-configuration.nix
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usbhid"
    "rtsx_pci_sdmmc"
  ];
  # Set of modules that are ALWAYS loaded by the initrd
  boot.initrd.kernelModules = [ "nvidia" ];
  # Set of kernel modules to be loaded in the second stage of the boot process
  boot.kernelModules = [
    "nvidia"
    "kvm-amd" # kernel-based VM support for AMD
  ];
  # additional packages supplying kernel modules
  boot.extraModulePackages = [ ];
  # specify eg. module options to be appended to the generated modprobe.conf
  boot.extraModprobeConfig = # bash
    ''
      # Add the S0ix module parameter
      options nvidia "NVreg_EnableS0ixPowerManagement=1"
      # change defaults to workaround the nvidia GPU freeze-on-resume problem
      # see https://bbs.archlinux.org/viewtopic.php?id=300676
      options nvidia "NVreg_PreserveVideoMemoryAllocations=0"
      # allows nvidia to manage the frame buffer device (experimental status)
      options "nvidia_drm.fbdev=0"
      # options nvidia "NVreg_TemporaryFilePath=/var/tmp"
      # set the default state of function lock (workaround for lack of Fn-Esc toggle)
      # NB: as at 8/01/2025, this is changing the value but the function lock is still fixed on
      options asus_wmi fnlock_default=N
    '';
  # Parameters added to the kernel command line
  boot.kernelParams = [ ];
}
