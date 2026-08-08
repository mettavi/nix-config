{
  config,
  inputs,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.podman;
in
{
  # to enable podman & podman systemd generator using the flake input
  imports = [ inputs.quadlet-nix.nixosModules.quadlet ];

  options.mettavi.system.services.podman = {
    enable = lib.mkEnableOption "Install and set up the nixos podman server";
    quadlet = mkOption {
      type = types.bool;
      description = "Configure podman using quadlets with a flake service";
      default = true;
    };
    # 🌟 NEW: We export our wrapper helper function as an option
    # so you can use it anywhere in your codebase!
    mkContainer = mkOption {
      type = types.functionTo types.attrs;
      description = "Helper function to inject shared timezone volumes into quadlets";
      default =
        containerConfig:
        lib.recursiveUpdate containerConfig {
          containerConfig.timezone = "local";
        };
    };
  };

  config = mkIf cfg.enable {
    users.users."${username}" = {
      extraGroups = [
        "podman"
        "video" # Required for /dev/nvidia* access from rootless containers
        "render" # Required for /dev/dri/* access from rootless containers
      ];
    };

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

    # enable podman & podman systemd generator using the podman quadlet flake
    virtualisation.quadlet = mkIf cfg.quadlet {
      enable = true;
      autoUpdate.enable = true;
    };
    home-manager.users.${username} = {
      # If using the 'quadlet-nix' home manager module syntax:
      virtualisation.quadlet = lib.mkIf cfg.quadlet {
        enable = true;
      };
    };
  };
}
