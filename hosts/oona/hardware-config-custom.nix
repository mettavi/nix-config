# All custom hardware code belongs here.
# The basic hardware scan code in hardware-configuration.nix should not be edited.
{
  config,
  lib,
  modulesPath,
  pkgs,
  username,
  ...
}:
let
  commonOptions = [
    "defaults"
    "discard"
    "noatime"
  ];
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.kernelModules = [
    "kvm-amd"
    "nvidia"
  ];
  boot.extraModprobeConfig = # bash
    ''
      # Add the S0ix module parameter
      options nvidia "NVreg_EnableS0ixPowerManagement=1"
      # make the PreserveVideo... option explicit, and set a Temporary File Path to prevent errors
      options nvidia "NVreg_PreserveVideoMemoryAllocations=1"
      options nvidia "NVreg_TemporaryFilePath=/var/tmp"
      # set the default state of function lock (workaround for lack of Fn-Esc toggle)
      # NB: as at 8/01/2025, this is changing the value but the function lock is still fixed on
      options asus_wmi fnlock_default=N
    '';
  boot.extraModulePackages = [ ];

  boot.supportedFilesystems = [
    "ntfs" # required to mount ntfs partitions
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/EE2C-39D6";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/24B4-5D5C";
    fsType = "vfat";
    # set these permissions to prevent the "random seed file is world accessible
    # which is a security hole" boot error
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # mount the HOME subvolume of the CachyOS partition
  fileSystems."/mnt/cachyos/home" = {
    device = "/dev/disk/by-uuid/2a1020bc-0b4e-4b74-a373-8e624aec1e11";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      "nofail"
      "subvol=@home"
    ];
  };

  # mount the main Windows 11 Pro partition
  fileSystems."/mnt/win11pro" = {
    device = "/dev/disk/by-uuid/D02CB4C42CB4A73E";
    fsType = "ntfs-3g";
    options = [
      "nofail"
      "rw"
      "uid=1000"
      "windows_names"
    ];
  };

  ################ BTRFS SUBVOLUMES ###################
  # To make a new TOP-LEVEL btrfs subvolume, mount the hidden root subvolume first:
  # eg. sudo mount /dev/nvme0n1p7 /mnt/btrfs && sudo btrfs subvolume create @subvolname
  # To easily make a NESTED btrfs subvolume, use the SAME NAME (without an @) as the existing directory:
  # eg. mv /var/cache /var/cache.bak && sudo btrfs subvolume create /var/cache
  # && cp -a --reflink=always /var/cache.bak/. /var/cache/
  # Such nested subvolumes inherit the settings of their parents and do not need to be added to /etc/fstab
  # NB: systemd (eg. /var/lib/portables and /var/lib/machines) and the os installer/other programs
  # (eg. /tmp, /var/tmp, /srv) may also auto-create nested btrfs subvolumes
  #####################################################

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    # NB: The default zstd compression level is 3.
    # This option is used across all subvolumes on the btrfs device
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@root"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@nix"
    ];
  };

  fileSystems."/root" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@roothome"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    # required on home directories for sops-nix to work with btrfs
    # See https://github.com/Mic92/sops-nix/issues/721
    neededForBoot = true;
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@home"
    ];
  };

  fileSystems."/home/${username}" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    neededForBoot = true;
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@adminhome"
    ];
  };

  fileSystems."/home/${username}/.local/share/containers" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@admincontainers"
    ];
  };

  fileSystems."/home/${username}/Downloads" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      # hide in the Nautilus devices menu
      "x-gvfs-hide"
      "subvol=@admindownloads"
    ];
  };

  fileSystems."/home/${username}/media" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      # hide in the Nautilus devices menu
      "x-gvfs-hide"
      "subvol=@adminmedia"
    ];
  };

  #fileSystems."/var/lib" = {
  #  device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
  #  fsType = "btrfs";
  #  neededForBoot = true;
  #  options = [ "subvol=@varlib" "compress=zstd" "noatime" ];
  #};

  fileSystems."/var/lib/containers" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@vlcontainers"
    ];
  };

  fileSystems."/var/lib/libvirt/images" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@libvirtimgs"
    ];
  };

  fileSystems."/var/lib/postgresql" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    # Ensures /var/lib is mounted first
    depends = [ "/var/lib" ];
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@vlpostgres"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@varlog"
    ];
  };

  fileSystems."/var/tmp" = {
    device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
    fsType = "btrfs";
    options = commonOptions ++ [
      "compress=zstd"
      "subvol=@vartmp"
    ];
  };

  # NB: The swap device is defined in the default hardware-configuration.nix

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Update the CPU microcode for AMD processors
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
