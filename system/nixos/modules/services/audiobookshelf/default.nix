{
  config,
  inputs,
  lib,
  username,
  ...
}:
let
  cfg = config.mettavi.system.services.audiobookshelf;
in
{
  options.mettavi.system.services.audiobookshelf = {
    enable = lib.mkEnableOption "Install and set up audiobookshelf server";
  };

  config = lib.mkIf cfg.enable {
    # to configure generic podman settings
    mettavi.system.services.podman.enable = true;
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
    # };
    home-manager.users.${username} =
      { config, ... }:
      {
        imports = [ inputs.quadlet-nix.homeManagerModules.quadlet ];
        virtualisation.quadlet =
          let
            inherit (config.virtualisation.quadlet) volumes;
          in
          {
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
                  userns = "keep-id";
                  volumes = [
                    "${volumes.audiobookshelf.ref}/Audiobooks:/audiobooks"
                    "${volumes.audiobookshelf.ref}/.config/audiobookshelf:/config"
                    "${volumes.audiobookshelf.ref}/.local/share/audiobookshelf:/metadata"
                  ];
                };
                serviceConfig = {
                  RestartSec = "10";
                  # Restart service when sleep finishes
                  Restart = "always";
                };
              };
            };
            volumes.audiobookshelf.volumeConfig = {
              type = "bind";
              device = config.home.homeDirectory;
            };
          };
      };

  };
}
