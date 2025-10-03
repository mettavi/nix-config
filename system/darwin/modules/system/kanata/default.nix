{
  config,
  lib,
  nix_repo,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.nyx.system.shell.kanata;
in
{
  options.nyx.system.shell.kanata = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install kanata on macOS, a tool to improve keyboard usability with advanced customization";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      macpkgs.karabiner-driverkit
      # kanata
      # install from gh commit to get recent bugfix, see https://github.com/jtroo/kanata/issues/1539
      macpkgs.kanata-head
    ];
    launchd.daemons = {
      # NB: The daemon is not used in version <3.1.0 of karabiner-driverkit
      kanata = {
        serviceConfig = {
          Label = "com.github.jtroo-kanata";
          ProgramArguments = [
            "/run/current-system/sw/bin/kanata"
            "-c"
            "${config.users.users.${username}.home}/${nix_repo}/home/shared/dots/kanata/kanata.lsp"
          ];
          ProcessType = "Interactive";
          RunAtLoad = true;
          # kanata loses connection to virtual keyboard after computer goes to sleeep, see https://github.com/jtroo/kanata/issues/1357
          # change KeepAlive to true as potential workaround
          KeepAlive = true;
          # KeepAlive = {
          #   # this keeps the kanata daemon alive whenever the karabiner daemon is alive
          #   OtherJobEnabled = {
          #     "org.pqrs.service.daemon.Karabiner-VirtualHIDDevice-Daemon" = true;
          #   };
          # };
          Nice = -30;
          StandardOutPath = "/var/log/kanata.log";
          StandardErrorPath = "/var/log/kanata.log";
        };
      };
      karabiner = {
        # logs are automatically saved to /var/log/karabiner/
        serviceConfig = {
          Label = "org.pqrs.service.daemon.Karabiner-VirtualHIDDevice-Daemon";
          ProcessType = "Interactive";
          # Change key used due to workaround bug in nix-darwin (as at 02092025),
          # see https://github.com/nix-darwin/nix-darwin/issues/1578 for details
          # Program = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
          ProgramArguments = [
            "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
          ];
          RunAtLoad = true;
          KeepAlive = {
            SuccessfulExit = false;
            Crashed = true;
          };
          Nice = -30;
        };
      };
    };
  };
}
