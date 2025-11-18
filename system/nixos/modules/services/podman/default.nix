{
  config,
  lib,
  ...
}:
let
  cfg = config.mettavi.system.services.podman;
in
{
  options.mettavi.system.services.podman = {
    enable = lib.mkEnableOption "Install and set up the nixos podman server";
  };

  config = lib.mkIf cfg.enable {
    # Enable common container config files in /etc/containers
    virtualisation.containers.enable = true;
    virtualisation.podman = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = [ "--all" ];
      };
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

  };
}
