{
  config,
  lib,
  username,
  ...
}:
let
  cfg = config.mettavi.system.services.audiobookshelf;
  # volumes = config.virtualisation.quadlet.volumes;
in
{
  options.mettavi.system.services.audiobookshelf = {
    enable = lib.mkEnableOption "Install and set up audiobookshelf server";
    abs_home = lib.mkOption {
      description = "The location of the audiobook library in the filesystem";
      type = lib.types.path;
      default = "${config.users.users.${username}.home}/Music/Audiobooks";
    };
  };

  config = lib.mkIf cfg.enable {
    # to configure generic podman settings
    mettavi.system.services.podman.enable = true;
    # open the port for ABS in the firewall
    networking.firewall.allowedTCPPorts = [ 13378 ];
    # to enable podman & podman systemd generator
    virtualisation.quadlet = {
      enable = true;
      autoUpdate.enable = true;
    };
    # users.users.${username} = {
    # required for auto start before user login
    # linger = true;
    # required for rootless container with multiple users
    # autoSubUidGidRange = true;
    # };{
    virtualisation.quadlet = {
      containers = {
        audiobookshelf = {
          autoStart = false;
          containerConfig = {
            autoUpdate = "registry";
            environments = {
              TZ = "Australia/Melbourne";
            };
            # pull from the github container registry (ghcr)
            image = "ghcr.io/advplyr/audiobookshelf:latest";
            noNewPrivileges = true;
            publishPorts = [ "13378:80" ];
            # the current user’s UID:GID are mapped to the same values in the container
            # required to become root and access the mounted volumes
            # WARNING: do not enable this option ("user namespace") as it causes "Error: listen EACCES: permission denied 0.0.0.0:80"
            # userns = "keep-id";

            # NB: Reverted to bind mounts as named volumes would not work with audiobookshelf
            # (the directories were all empty)
            volumes = [
              # bind mounts
              "${config.mettavi.system.services.audiobookshelf.abs_home}:/audiobooks"
              "${config.users.users.${username}.home}/.config/audiobookshelf:/config"
              "${config.users.users.${username}.home}/.local/share/audiobookshelf/metadata:/metadata"
              # named volume mounts
              # "${volumes.abs-home.ref}:/audiobooks"
              # "${volumes.abs-cfg.ref}:/config"
              # "${volumes.abs-meta.ref}:/metadata"
            ];
          };
          serviceConfig = {
            RestartSec = "10";
            # Restart service when sleep finishes
            Restart = "always";
          };
        };
      };
      # use named volumes for data persistence, not bind mounts
      # NB: these are not used currently due to a problem with the audiobookshelf service
      volumes = {
        abs-home = {
          autoStart = false;
          volumeConfig = {
            device = "${config.mettavi.system.services.audiobookshelf.abs_home}";
            globalArgs = [ "--log-level=debug" ];
            type = "bind";
            # user = "${username}";
          };
        };
        abs-cfg = {
          autoStart = false;
          volumeConfig = {
            device = "${config.users.users.${username}.home}/.config/audiobookshelf";
            type = "bind";
          };
        };
        abs-meta = {
          autoStart = false;
          volumeConfig = {
            device = "${config.users.users.${username}.home}/.local/share/audiobookshelf/metadata";
            type = "bind";
          };
        };
      };
    };
  };
}
