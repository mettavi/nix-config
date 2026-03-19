# NB: nvidia config is in a separate module
{ lib, pkgs, ... }:
with lib;
{
  # override the Linux kernel (and hence its kernel modules) used by NixOS
  # Use the cachyos kernel for the latest asus g14 kernel patches (using custom flake input and overlay)
  # for nixos default kernels, see pkgs.linuxKernel.kernels.linux* in nixpkgs
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest; # default pkgs.linuxPackages_latest

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
  boot.initrd.kernelModules = [ ];
  # Set of kernel modules to be loaded in the second stage of the boot process
  boot.kernelModules = [
    "kvm-amd" # kernel-based VM support for AMD
  ];
  # additional packages supplying kernel modules
  boot.extraModulePackages = [ ];
  # specify eg. module options to be added to /etc/modprobe.d/
  # can be used for both built-in and loadable kernel modules
  boot.extraModprobeConfig = # bash
    ''
      # set the default state of function lock (workaround for lack of Fn-Esc toggle)
      # NB: as at 8/01/2025, this is changing the value but the function lock is still fixed on
      options asus_wmi fnlock_default=N
    '';
  # Parameters added to the kernel command line (can only be used for built-in modules)
  boot.kernelParams = [ ];

  # SysRq shortcuts can be used to trigger a more graceful reboot
  boot.kernel.sysctl."kernel.sysrq" = mkDefault 1;

}
