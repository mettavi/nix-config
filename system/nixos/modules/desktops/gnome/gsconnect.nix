{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.desktops.gnome;
  # TODO: Remove the nixpkgs input for the gsconnect package when nixpkgs PR
  # https://nixpk.gs/pr-tracker.html?pr=524726 is merged to nixos-unstable
  # See https://github.com/NixOS/nixpkgs/pull/524726/ for details
  nixpkgs = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.mettavi.system.desktops.gnome = {
    gsconnect = mkOption {
      type = types.bool;
      default = true;
      description = "Install the gsconnect (kdeconnect) extension";
    };
  };

  config = mkIf (cfg.enable && cfg.gsconnect) {
    networking.firewall = rec {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = allowedTCPPortRanges;
    };
    home-manager.users.${username} = {
      home.packages = with nixpkgs.gnomeExtensions; [
        gsconnect # KDE Connect implementation for GNOME
      ];
      dconf.settings = {
        "org/gnome/shell" = {
          # auto-enable installed extensions (run `gnome-extensions list` for a list)
          enabled-extensions = [
            "gsconnect@andyholmes.github.io"
          ];
        };

      };
      programs.firefox = {
        nativeMessagingHosts = with pkgs.gnomeExtensions; [
          gsconnect
        ];
        profiles."mettavi".extensions = {
          packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [ gsconnect ];
        };
      };
    };
  };
}
