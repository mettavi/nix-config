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
      home.packages = with pkgs.gnomeExtensions; [
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
