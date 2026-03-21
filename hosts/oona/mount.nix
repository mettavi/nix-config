# All custom hardware code belongs here.
# The basic hardware scan code in hardware-configuration.nix should not be edited.
{
  lib,
  username,
  ...
}:
with lib;
let
  commonOptions = [
    "defaults"
    "discard"
    "noatime"
  ];
in
{
  boot.supportedFilesystems = [
    "ntfs" # required to mount ntfs partitions
  ];

  # NB: The swap device is defined in the default hardware-configuration.nix

  fileSystems =
    let
      device = mkForce "/dev/disk/by-label/nixos";
    in
    {
      "/boot" = {
        device = mkForce "/dev/disk/by-uuid/EE2C-39D6";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };
      "/efi" = {
        device = mkForce "/dev/disk/by-uuid/24B4-5D5C";
        fsType = "vfat";
        # set these permissions to prevent the "random seed file is world accessible
        # which is a security hole" boot error
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
      # mount the HOME subvolume of the CachyOS partition
      "/mnt/cachyos/home" = {
        device = mkForce "/dev/disk/by-uuid/2a1020bc-0b4e-4b74-a373-8e624aec1e11";
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "nofail"
          "subvol=@home"
        ];
      };
      # mount the main Windows 11 Pro partition
      "/mnt/win11pro" = {
        device = "/dev/disk/by-uuid/D02CB4C42CB4A73E";
        fsType = "ntfs-3g";
        options = [
          "nofail"
          "rw"
          "uid=1000"
          "windows_names"
        ];
      };
      "/" = {
        inherit device;
        fsType = "btrfs";
        # NB: The default zstd compression level is 3.
        # This option is used across all subvolumes on the btrfs device
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@root"
        ];
      };
      "/nix" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@nix"
        ];
      };
      "/root" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@roothome"
        ];
      };
      "/home" = {
        inherit device;
        fsType = "btrfs";
        # required on home directories for sops-nix to work with btrfs
        # See https://github.com/Mic92/sops-nix/issues/721
        neededForBoot = true;
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@home"
        ];
      };
      "/home/${username}" = {
        inherit device;
        fsType = "btrfs";
        neededForBoot = true;
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@adminhome"
        ];
      };
      "/home/${username}/.local/share/containers" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@admincontainers"
          "x-gvfs-trash" # Enables trash functionality in Files app (Nautilus)
        ];
      };
      "/home/${username}/Downloads" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@admindownloads"
          "x-gvfs-hide" # hide in the Nautilus devices menu
          "x-gvfs-trash" # Enables trash functionality in Files app (Nautilus)
        ];
      };
      "/home/${username}/media" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@adminmedia"
          "x-gvfs-hide" # hide in the Nautilus devices menu
          "x-gvfs-trash" # Enables trash functionality in Files (Nautilus) for the mounted filesystem
        ];
      };
      "/var/lib/containers" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@vlcontainers"
        ];
      };
      "/var/lib/libvirt/images" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@libvirtimgs"
        ];
      };
      "/var/lib/postgresql" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@vlpostgres"
        ];
      };
      "/var/log" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@varlog"
        ];
      };
      "/var/tmp" = {
        inherit device;
        fsType = "btrfs";
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@vartmp"
        ];
      };
    };

  ######################################################
  # SET NO COPY-ON-WRITE ON SPECIAL BTRFS SUBVOLUMES
  # NB: 1) Setting this by a mount option will apply the option to ALL subvolumes on the partition.
  #        This method (using systemd tmpfiles) allows it to be set per subvolume.
  #     2) This is best used on an empty directory as it only applies to NEW files.
  #     3) Disabling COW will also disable btrfs compression and file integrity checksumming.

  systemd.tmpfiles.rules = [
    # type path mode user group (expiry) (argument)
    "h /var/lib/libvirt/images - - - - +C"
    "h /var/lib/postgresql - - - - +C"
  ];
}
