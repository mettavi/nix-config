{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.mettavi.services.gramps-web;
in
{
  options.mettavi.services.gramps-web = {
    enable = lib.mkEnableOption "Install and set up the gramps-web service";
  };

  imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

  config = lib.mkIf cfg.enable {
    # to enable and configure generic podman settings
    mettavi.system.services.podman.enable = true;
    # open the port for ABS in the firewall
    networking.firewall.allowedTCPPorts = [ 5000 ];
    # users.users.${username} = {
    # required for auto start before user login
    # linger = true;
    # required for rootless container with multiple users
    # autoSubUidGidRange = true;
    # };
    home-manager.users."${username}" = {
      virtualisation.quadlet =
        let
          inherit (config.virtualisation.quadlet) volumes;
          image = pkgs.dockerTools.buildImage {
            name = "grampsweb-cuda";
            tag = "latest";

            # pull from the github container registry (ghcr)
            fromImage = ghcr.io/gramps-project/grampsweb;
            fromImageName = null;
            fromImageTag = "latest";
            copyToRoot = pkgs.buildEnv {
              name = "torch-cuda";
              paths = with pkgs; [ pythonPackages.torchWithCuda ];
              pathsToLink = [ "/bin" ];
            };
          };
        in
        {
          containers = {
            grampsweb = {
              # autoStart = false;
              containerConfig = {
                autoUpdate = "registry";
                environments = {
                  TZ = "Australia/Melbourne";
                  GRAMPSWEB_TREE = "Allen"; # will create a new tree if not exists
                  GRAMPSWEB_TREE_ID = "${config.xdg.dataHome}/gramps/grampsdb/69db313a";
                  GRAMPSWEB_CELERY_CONFIG__broker_url = "redis://grampsweb_redis:6379/0";
                  GRAMPSWEB_CELERY_CONFIG__result_backend = "redis://grampsweb_redis:6379/0";
                  GRAMPSWEB_RATELIMIT_STORAGE_URI = "redis://grampsweb_redis:6379/1";
                  GRAMPSWEB_VECTOR_EMBEDDING_MODEL = "sentence-transformers/distiluse-base-multilingual-cased-v2";
                };
                image = "docker-archive:${image}";
                noNewPrivileges = true;
                publishPorts = [ "5000:5000" ]; # host:container
                # the current user’s UID:GID are mapped to the same values in the container
                # required to become root and access the mounted volumes
                # WARNING: do not enable this option ("user namespace") as it causes "Error: listen EACCES: permission denied 0.0.0.0:80"
                # userns = "keep-id";

                # create mounts using the "podman run --volume ..." syntax
                volumes = [
                  # bind mounts
                  "${config.home.homeDirectory}/media/gramps/allen/:/app/media"
                  "${config.xdg.configHome}/gramps/allen.cfg/:/app/config/config.cfg"
                  # volume mounts
                  "${volumes.gramps_users.ref}:/app/users" # persist user database
                  "${volumes.gramps_index.ref}:/app/indexdir" # persist search index
                  "${volumes.gramps_thumb_cache.ref}:/app/thumbnail_cache" # persist thumbnails
                  "${volumes.gramps_cache.ref}:/app/cache" # persist export and report caches
                  "${volumes.gramps_secret.ref}:/app/secret" # persist flask secret
                  "${volumes.gramps_db.ref}:/root/.gramps/grampsdb" # persist Gramps database
                  "${volumes.gramps_tmp.ref}:/tmp"
                ];
              };
              serviceConfig = {
                Restart = "always";
              };
              unitConfig = {
                After = "grampsweb_redis";
                Requires = "grampsweb_redis";
              };
            };
            grampsweb_celery = config.virtualisation.quadlet.containers.grampsweb.ref // {
              containerConfig = {
                exec = "celery -A gramps_webapi.celery worker --loglevel=INFO --concurrency=2";
                name = "grampsweb_celery";
                publishPorts = [ ];
              };
              unitConfig = {
                After = [
                  "grampsweb"
                  "grampsweb_redis"
                ];
                Requires = [
                  "grampsweb"
                  "grampsweb_redis"
                ];
              };
            };
            grampsweb_redis = {
              containerConfig = {
                image = "docker.io/valkey/valkey:8-alpine";
                name = "grampsweb_redis";
              };
              serviceConfig = {
                Restart = "always";
              };
            };
          };
          # create named volumes
          volumes =
            let
              gramps-vols = [
                "gramps_users"
                "gramps_index"
                "gramps_thumb_cache"
                "gramps_cache"
                "gramps_secret"
                "gramps_db"
                "gramps_tmp"
              ];
            in
            lib.listToAttrs (
              map (vol: {
                # the device to be mounted, equivalent to the device argument to mount(8)
                device = "/dev/nvme0n1p7";
                # the type of the filesystem to be mounted, equivalent to the -t flag to mount(8)
                type = "btrfs";
              }) gramps-vols
            );
          # user = "${username}";
        };
    };
  };
}
