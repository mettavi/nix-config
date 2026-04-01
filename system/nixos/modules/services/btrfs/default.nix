{
  config,
  lib,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.mettavi.system.services.btrfs;
in
{
  options.mettavi.system.services.btrfs = {
    enable = mkEnableOption "Manage the btrfs filesystem";
    dedupe = mkOption {
      description = "Whether to run block-based dedupe on btrfs volumes";
      type = bool;
      default = true;
    };
    vol_label = mkOption {
      description = "The label of the root btrfs subvolume";
      type = str;
      default = "nixos";
    };
  };

  config = lib.mkIf cfg.enable {
    # CHECK BTRFS FILE CONSISTENCY
    # check the status of the last scrub with "btrfs scrub status /" or in the journal
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };

    services.beesd = mkIf cfg.dedupe {
      filesystems = {
        root = {
          # Filesystem to run bees dedupe on (can also be a path):
          # Note that deduplication crosses subvolumes; one must
          # not configure multiple instances for subvolumes of the same filesystem
          # (or block devices which are part of the same filesystem), but only for
          # completely independent btrfs filesystems.
          spec = "LABEL=${cfg.vol_label}";

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

    # install bees from master for recent bugfixes
    # see https://github.com/Zygo/bees/issues/336
    nixpkgs.overlays = [
      (final: prev: {
        bees = prev.bees.overrideAttrs (old: {
          version = "master";
          src = prev.fetchFromGitHub {
            owner = "Zygo";
            repo = "bees";
            rev = "b8086fb41af052bdadf35dc13382604e246dc12c";
            hash = "sha256-HmXCQB477AhEo7dormAv+d7jz4cKiQEHQie9VvUqUzM=";
          };
        });
      })
    ];

  };
}
