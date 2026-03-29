# All custom hardware code belongs here.
# The basic hardware scan code in hardware-configuration.nix should not be edited.
{
  lib,
  username,
  ...
}:
with lib;
{
  boot.supportedFilesystems = [
    "ntfs" # required to mount ntfs partitions
  ];

  # NB: The swap device is defined in the default hardware-configuration.nix

  fileSystems =
    let
      btrfsOptions = [ "compress=zstd" ];
      commonOptions = [
        "defaults"
        "discard"
        "noatime"
      ];
      # NB: this is the same as `label = "nixos"`
      device = mkForce "/dev/disk/by-label/nixos";
      fsType = "btrfs";
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
        inherit fsType;
        device = mkForce "/dev/disk/by-uuid/2a1020bc-0b4e-4b74-a373-8e624aec1e11";
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
        inherit device fsType;
        # NB: The default zstd compression level is 3.
        # NB: Most btrfs options are common to all subvolumes on the btrfs partition
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@root"
          ];
      };
      "/nix" = {
        inherit device fsType;
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@nix"
          ];
      };
      "/root" = {
        inherit device fsType;
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@roothome"
          ];
      };
      "/home" = {
        inherit device fsType;
        # required on home directories for sops-nix to work with btrfs
        # See https://github.com/Mic92/sops-nix/issues/721
        neededForBoot = true;
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@home"
          ];
      };
      "/home/${username}" = {
        inherit device fsType;
        neededForBoot = true;
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@adminhome"
          ];
      };
      "/home/${username}/.local/share/containers" = {
        inherit device fsType;
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@admincontainers"
            "x-gvfs-trash" # Enables trash functionality in Files app (Nautilus) for the mounted filesystem
          ];
      };
      "/home/${username}/Downloads" = {
        inherit device fsType;
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@admindownloads"
            "x-gvfs-hide" # hide in the Nautilus devices menu
            "x-gvfs-trash"
          ];
      };
      "/home/${username}/media" = {
        inherit device fsType;
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@adminmedia"
            "x-gvfs-hide"
            "x-gvfs-trash"
          ];
      };
      "/var/lib/containers" = {
        inherit device fsType;
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@vlcontainers"
          ];
      };
      "/var/lib/libvirt/images" = {
        inherit device;
        fsType = "btrfs";
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@libvirtimgs"
          ];
      };
      "/var/lib/postgresql" = {
        inherit device fsType;
        options = commonOptions ++ [
          "compress=zstd"
          "subvol=@vlpostgres"
        ];
      };
      "/var/log" = {
        inherit device;
        fsType = "btrfs";
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@varlog"
          ];
      };
      "/var/tmp" = {
        inherit device fsType;
        options =
          commonOptions
          ++ btrfsOptions
          ++ [
            "subvol=@vartmp"
          ];
      };
    };

  # CHECK BTRFS FILE CONSISTENCY
  # check the status of the last scrub with "btrfs scrub status /" or in the journal
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  services.beesd = {
    filesystems = {
      root = {
        # Filesystem to run bees dedupe on (can also be a path):
        # Note that deduplication crosses subvolumes; one must
        # not configure multiple instances for subvolumes of the same filesystem
        # (or block devices which are part of the same filesystem), but only for
        # completely independent btrfs filesystems.
        spec = "LABEL=nixos";

        # 1 GB hash table size, also maps to RAM
        # must be a multiple of 16MB
        hashTableSizeMB = 1024;

        # This caches block fingerprints to check newly
        # written blocks against existing. Too small and
        # dedupe rates suffer. Too large just wastes RAM.

        # unique data size |  hash table size |average dedupe extent size
        #     1TB          |      4GB         |        4K
        #     1TB          |      1GB         |       16K
        #     1TB          |    256MB         |       64K
        #     1TB          |    128MB         |      128K
        #     1TB          |     16MB         |     1024K
        #    64TB          |      1GB         |     1024K
        # Source: https://github.com/Zygo/bees/blob/master/docs/config.md

        # location of hash table
        workDir = ".beeshome";

        # emerg = 0; alert = 1; crit = 2; err = 3; warning = 4; notice = 5; info = 6 (default); debug = 7;
        verbosity = "info";

        extraOptions = [
          # Max load avg target before throttling (default is no throttling)
          "--loadavg-target"
          "4.0"
          # Number of worker threads to use (default is 1 per cpu core)
          "--thread-count"
          "6"
        ];
      };
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
