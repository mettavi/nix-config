{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mettavi.services.gramps-web;

  # 1. Define a standard Containerfile to build the GPU-enabled image
  # This avoids the Nix-store/FHS mismatch by using standard pip in the container.
  grampsCudaContainerfile = pkgs.writeText "Containerfile" ''
    FROM ghcr.io/gramps-project/grampsweb:latest
    # Install PyTorch with CUDA 12.1 support directly into the container's environment
    RUN pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
  '';

  # 2. Extract shared configuration so both grampsweb and celery can inherit it properly
  sharedContainerEnv = {
    TZ = "Australia/Melbourne";
    GRAMPSWEB_TREE = "Allen";
    GRAMPSWEB_TREE_ID = "${config.xdg.dataHome}/gramps/grampsdb/69db313a";
    GRAMPSWEB_CELERY_CONFIG__broker_url = "redis://grampsweb_redis:6379/0";
    GRAMPSWEB_CELERY_CONFIG__result_backend = "redis://grampsweb_redis:6379/0";
    GRAMPSWEB_RATELIMIT_STORAGE_URI = "redis://grampsweb_redis:6379/1";
    GRAMPSWEB_VECTOR_EMBEDDING_MODEL = "sentence-transformers/distiluse-base-multilingual-cased-v2";
  };

  sharedVolumes = [
    "${config.home.homeDirectory}/media/gramps/allen/:/app/media"
    "${config.xdg.configHome}/gramps/allen.cfg/:/app/config/config.cfg"
    # Replaced raw device mounts with standard named volume references
    "gramps_users:/app/users"
    "gramps_index:/app/indexdir"
    "gramps_thumb_cache:/app/thumbnail_cache"
    "gramps_cache:/app/cache"
    "gramps_secret:/app/secret"
    "gramps_db:/root/.gramps/grampsdb"
    "gramps_tmp:/tmp"
  ];

in
{
  options.mettavi.services.gramps-web = {
    enable = lib.mkEnableOption "Install and set up the gramps-web service";
  };

  imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

  config = lib.mkIf cfg.enable {
    mettavi.system.services.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 5000 ];

    # Ensure NVIDIA Container Toolkit is enabled at the OS level so Podman can pass the GPU
    hardware.nvidia-container-toolkit.enable = true;

    virtualisation.quadlet = {
      # Create a shared network so the containers can resolve 'grampsweb_redis'
      networks = {
        gramps_net = { };
      };

      # Define the image build process
      images = {
        grampsweb_cuda = {
          imageConfig = {
            File = "${grampsCudaContainerfile}";
            ImageTag = "grampsweb:cuda";
          };
        };
      };

      containers = {
        grampsweb = {
          containerConfig = {
            # Use the image we built above
            image = "localhost/grampsweb:cuda";
            environments = sharedContainerEnv;
            volumes = sharedVolumes;
            publishPorts = [ "5000:5000" ];
            network = [ "gramps_net.network" ]; # Attach to shared network
            noNewPrivileges = true;

            # Pass the NVIDIA GPU to the container
            devices = [ "nvidia.com/gpu=all" ];
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            # Ensure the image is built and redis is running first
            After = [
              "grampsweb_redis.container"
              "grampsweb_cuda.image"
            ];
            Requires = [
              "grampsweb_redis.container"
              "grampsweb_cuda.image"
            ];
          };
        };

        grampsweb_celery = {
          containerConfig = {
            image = "localhost/grampsweb:cuda";
            exec = "celery -A gramps_webapi.celery worker --loglevel=INFO --concurrency=2";
            environments = sharedContainerEnv;
            volumes = sharedVolumes;
            network = [ "gramps_net.network" ];
            devices = [ "nvidia.com/gpu=all" ]; # Celery likely needs the GPU for embedding tasks too
          };
          serviceConfig = {
            Restart = "always";
          };
          unitConfig = {
            After = [
              "grampsweb.container"
              "grampsweb_redis.container"
            ];
            Requires = [
              "grampsweb.container"
              "grampsweb_redis.container"
            ];
          };
        };

        grampsweb_redis = {
          containerConfig = {
            image = "docker.io/valkey/valkey:8-alpine";
            network = [ "gramps_net.network" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };
      };

      # Define named volumes normally (letting Podman manage the storage backend)
      volumes = {
        gramps_users = { };
        gramps_index = { };
        gramps_thumb_cache = { };
        gramps_cache = { };
        gramps_secret = { };
        gramps_db = { };
        gramps_tmp = { };
      };
    };
  };
}
