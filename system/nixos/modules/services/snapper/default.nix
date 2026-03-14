{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.snapper;
in
{
  options.mettavi.system.services.snapper = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure automatic btrfs snapshots using snapper";
    };
  };

  config = mkIf cfg.enable {
    services.snapper =
      let
        commonConfig = {
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "10";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "0";
          TIMELINE_LIMIT_MONTHLY = "0";
          TIMELINE_LIMIT_YEARLY = "0";
          BACKGROUND_COMPARISON = "yes";
          NUMBER_CLEANUP = "no";
          NUMBER_MIN_AGE = "1800";
          NUMBER_LIMIT = "50";
          NUMBER_LIMIT_IMPORTANT = "10";
          EMPTY_PRE_POST_CLEANUP = "yes";
          EMPTY_PRE_POST_MIN_AGE = "1800";
        };
      in
      {
        snapshotInterval = "hourly";
        cleanupInterval = "1d";
        configs = {
          adminhome = commonConfig // {
            SUBVOLUME = "/home/${username}";
          };
          adminmedia = commonConfig // {
            SUBVOLUME = "/home/${username}/media";
          };
          postgres = commonConfig // {
            SUBVOLUME = "/var/lib/postgresql";
          };
        };
      };

    # create nested .snapshots subvolumes to store the snapshots taken by snapper
    # NB: The .snapshots directory must be owned by root and must not be writable (eg. r-x) by anybody else.
    systemd.tmpfiles.rules = [
      # type path mode user group (expiry)
      "v /home/${username}/.snapshots 0750 root ${username} -"
      "v /home/${username}/media/.snapshots 0750 root ${username} -"
      "v /var/lib/postgresql/.snapshots 0750 root ${username} -"
    ];
  };
}
