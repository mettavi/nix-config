# All custom hardware code belongs here.
# The basic hardware scan code in hardware-configuration.nix should not be edited.
{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  commonOptions = [
    "defaults"
    "discard"
    "noatime"
  ];
  btrfsOptions = [
    "x-systemd.requires=pre-btrfs-mount.service"
    "x-systemd.after=pre-btrfs-mount.service"
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

  # Asus kernel patches
  #  boot.kernelPatches = let
  #     version = config.boot.kernelPackages.kernel.version;
  # in [
  #   {
  #     name = "g14";
  #     patch = builtins.fetchurl {
  # url = "https://gitlab.com/dragonn/linux-g14/-/raw/${lib.versions.majorMinor version}/asus-patch-series.patch";
  # url = "https://gitlab.com/asus-linux/fedora-kernel/-/raw/rog-${lib.versions.majorMinor version}/asus-patch-series.patch";
  #        url = "https://gitlab.com/asus-linux/linux-g14/-/raw/${lib.versions.majorMinor version}/asus-patch-series.patch";
  #       sha256 = "0fgbv87z7jyi6f2y0mm246pv7p0nhvznpbmdlf04gl9xinvs2g5m";
  #     };
  # structuredExtraConfig = with lib.kernel; {
  #   ASUS_ARMOURY = module;
  # ASUS_WMI_BIOS = yes;
  # };
  #     extraMeta = {
  #       branch = lib.versions.majorMinor version;
  #     };
  #   }
  # ];

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
    # set these permissions to prevent the "random seed file is world accessible which is a security hole" boot error
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # CHECK BTRFS FILE CONSISTENCY
  # check the status of the last scrub with "btrfs scrub status /" or in the journal
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # NB: systemd may also auto-create var/lib/portables and var/lib/machines nested btrfs subvolumes
  # and the nixos installer or other programs may create nested subvolumes (eg. tmp, var/tmp, srv)
  # Nested subvolumes inherit the settings of their parents and do not need to be added to /etc/fstab
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

  # fileSystems."/home/${username}" = {
  #   device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
  #   fsType = "btrfs";
  #   neededForBoot = true;
  #   options = commonOptions ++ [
  #     "compress=zstd"
  #     "subvol=@homeadmin"
  #   ];
  # };

  # fileSystems."/home/${username}/media" = {
  #   device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
  #   fsType = "btrfs";
  #   options = commonOptions ++ [
  #     "compress=zstd"
  #     "subvol=@adminmedia"
  #   ];
  # };

  # fileSystems."/home/${username}/.local/share/containers" = {
  #   device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
  #   fsType = "btrfs";
  #   options = commonOptions ++ [
  #     "compress=zstd"
  #     "subvol=@admincontainers"
  #   ];
  # };

  # fileSystems."/home/${username}/Downloads" = {
  #   device = "/dev/disk/by-uuid/f8d2d292-064d-403d-8578-cddd38a090e8";
  #   fsType = "btrfs";
  #   options = commonOptions ++ [
  #     "compress=zstd"
  #     "subvol=@admindownloads"
  #   ];
  # };

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

  # mount the CachyOS partition
  # fileSystems."/mnt/cachyos" = {
  #   device = "/dev/disk/by-uuid/79b393a3-adfe-4033-aeb6-0397aa8581e3";
  #   fsType = "btrfs";
  # NB: The default zstd compression level is 3.
  # This option is used across all subvolumes on the btrfs device
  #   options = commonOptions ++ [
  #     "subvol=@"
  #     "compress=zstd"
  #      "nofail"
  #   ];
  #  };

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

  # NB: The swap device is defined in the default hardware-configuration.nix

  systemd.services."pre-btrfs-mount" = {
    enable = false;
    description = "Make directories to be mounted on btrfs subvolumes immutable to prevent them being written to when unmounted";
    before = [
      "-.mount"
      "nix.mount"
      "root.mount"
      "var-lib-containers.mount"
      "var-lib-libvirt-images.mount"
      "var-lib-postgresql.mount"
      "var-log.mount"
      "var-tmp.mount"
      "home.mount"
    ];
    path = with pkgs; [ e2fsprogs ];
    script = ''
      # see https://serverfault.com/a/570271
      chattr +i / /nix /var/log /var/lib/containers /var/lib/libvirt/images /var/lib/postgresql /var/log /var/tmp /home
    '';
    serviceConfig = {
      RemainAfterExit = true;
      Type = "oneshot";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # SET NO COPY-ON-WRITE ON SPECIAL BTRFS SUBVOLUMES
  # NB: 1) Setting this by a mount option will apply the option to ALL subvolumes on the partition.
  #        This method (using systemd tmpfiles) allows it to be set per subvolume.
  #     2) This is best used on an empty directory as it only applies to NEW files.
  #     3) Disabling COW will also disable btrfs file integrity checksumming.
  systemd.tmpfiles.rules = [
    # type path mode user group (expiry)
    "h /var/lib/libvirt/images - - - - +C"
    "h /var/lib/postgresql - - - - +C"
  ];

  # make it certain that the above systemd tmpfiles rules are executed
  # AFTER the btrfs subvolumes have been mounted
  systemd.services.systemd-tmpfiles-setup = {
    requires = [
      "var-lib-libvirt-images.mount"
      "var-lib-postgresql.mount"
    ];
    after = [
      "var-lib-libvirt-images.mount"
      "var-lib-postgresql.mount"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Update the CPU microcode for AMD processors
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
