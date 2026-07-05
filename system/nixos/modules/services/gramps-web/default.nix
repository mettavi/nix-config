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

  config = lib.mkIf cfg.enable {

    # --- SYSTEM-LEVEL CONFIGURATIONS ---
    mettavi.system.services.podman.enable = true;
    networking.firewall.allowedTCPPorts = [ 5000 ];

    # Explicitly assign SubUID/SubGID ranges and enable linger for auto-start
    users.users."${username}" = {
      autoSubUidGidRange = true;
      linger = true;
    };

    # --- HOME MANAGER (USER-LEVEL) CONFIGURATIONS ---
    home-manager.users."${username}" =
      { config, ... }:
      let
        inherit (config.virtualisation.quadlet) volumes;
        # 1. Define a standard Containerfile to build the GPU-enabled image
        # This avoids the Nix-store/FHS mismatch by using standard pip in the container.
        grampsCudaContainerfile = pkgs.writeText "Containerfile" ''
          FROM ghcr.io/gramps-project/grampsweb:latest
          # Uninstall the built-in CPU versions first to guarantee a clean slate,
          # then install the CUDA-enabled versions.
          RUN pip uninstall -y torch torchvision && \
            pip install torch torchvision --extra-index-url https://download.pytorch.org/whl/cu121
        '';

        # 2. Extract shared configuration so both grampsweb and celery can inherit it properly
        sharedContainerEnv = {
          TZ = "Australia/Melbourne";
          GRAMPSWEB_TREE = "Allen";

          GRAMPSWEB_CELERY_CONFIG__broker_url = "redis://grampsweb_redis:6379/0";
          GRAMPSWEB_CELERY_CONFIG__result_backend = "redis://grampsweb_redis:6379/0";
          GRAMPSWEB_RATELIMIT_STORAGE_URI = "redis://grampsweb_redis:6379/1";
          GRAMPSWEB_VECTOR_EMBEDDING_MODEL = "sentence-transformers/distiluse-base-multilingual-cased-v2";

          # Use Podman's special DNS name to reach the host, and add /v1 for the OpenAI API format
          LLM_BASE_URL = "http://host.containers.internal:11434/v1";
          # Replace this with whichever model you pulled via `ollama run <model>`
          LLM_MODEL = "qwen3:8b";
          # Ollama doesn't use authentication, but the Gramps client requires this field to not be empty
          OPENAI_API_KEY = "dummy-key-for-ollama";
        };

        sharedVolumes = [
          "${config.home.homeDirectory}/media/gramps/allen:/app/media"
          "${config.xdg.configHome}/gramps-web/allen.cfg:/app/config/config.cfg"
          # Replaced raw device mounts with standard named volume references
          "${volumes.gramps_users.ref}:/app/users"
          "${volumes.gramps_index.ref}:/app/indexdir"
          "${volumes.gramps_thumb_cache.ref}:/app/thumbnail_cache"
          "${volumes.gramps_cache.ref}:/app/cache"
          "${volumes.gramps_secret.ref}:/app/secret"
          "${volumes.gramps_db.ref}:/root/.gramps/grampsdb"
          "${volumes.gramps_tmp.ref}:/tmp"
        ];
      in
      {
        imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];

        virtualisation.quadlet =
          let
            inherit (config.virtualisation.quadlet) builds containers;
          in
          {
            # Create a shared network so the containers can resolve 'grampsweb_redis'
            networks = {
              gramps_net = { };
            };

            # Define the image build process
            builds = {
              grampsweb_cuda = {
                buildConfig = {
                  file = grampsCudaContainerfile.outPath;
                  tag = "grampsweb:cuda";
                  # Add this to force Podman to look at the config directory instead of the Nix Store
                  # contextType = "configdir";
                };
              };
            };

            containers = {
              grampsweb = {
                autoStart = true;
                containerConfig = {
                  # Use the image we built above
                  image = builds.grampsweb_cuda.ref;
                  environments = sharedContainerEnv;
                  volumes = sharedVolumes;
                  publishPorts = [ "0.0.0.0:5000:5000" ];

                  # COMPLETELY REMOVE the networks key
                  # Use ONLY podmanArgs to pass the explicit rootless string flag
                  podmanArgs = [
                    "--network=gramps_net"
                    "--group-add=keep-groups"
                  ];

                  noNewPrivileges = true;

                  # Keep user ID mapping the same as the host to fix bind mount permissions
                  # this requires not using any privileged ports (below 1024)
                  # userns = "keep-id";
                  # Pass the NVIDIA GPU to the container
                  devices = [ "nvidia.com/gpu=all" ];
                };
                serviceConfig = {
                  Restart = "always";
                };
                unitConfig = {
                  # Ensure the image is built and redis is running first
                  After = [
                    containers.grampsweb_redis.ref
                    builds.grampsweb_cuda.ref
                    config.virtualisation.quadlet.networks.gramps_net.ref
                  ];
                  Requires = [
                    containers.grampsweb_redis.ref
                    builds.grampsweb_cuda.ref
                    config.virtualisation.quadlet.networks.gramps_net.ref
                  ];
                };
              };

              grampsweb_celery = {
                containerConfig = {
                  image = "localhost/grampsweb:cuda";
                  exec = "celery -A gramps_webapi.celery worker --loglevel=INFO --concurrency=2";
                  environments = sharedContainerEnv;
                  volumes = sharedVolumes;

                  # Use ONLY podmanArgs here too
                  podmanArgs = [
                    "--network=gramps_net"
                    "--group-add=keep-groups"
                  ];

                };
                serviceConfig = {
                  Restart = "always";
                };
                unitConfig = {
                  After = [
                    "grampsweb.service"
                    containers.grampsweb_redis.ref
                    config.virtualisation.quadlet.networks.gramps_net.ref
                  ];
                  Requires = [
                    "grampsweb.service"
                    containers.grampsweb_redis.ref
                    config.virtualisation.quadlet.networks.gramps_net.ref
                  ];
                };
              };

              grampsweb_redis = {
                containerConfig = {
                  image = "docker.io/valkey/valkey:8-alpine";

                  # COMPLETELY REMOVE the networks key
                  # Use ONLY podmanArgs to pass the explicit rootless string flag
                  podmanArgs = [ "--network=gramps_net" ];

                };
                unitConfig = {
                  # Use the direct systemd service reference generated by quadlet-nix
                  After = [ config.virtualisation.quadlet.networks.gramps_net.ref ];
                  Requires = [ config.virtualisation.quadlet.networks.gramps_net.ref ];
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
  };
}
