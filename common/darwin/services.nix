{ config, ... }:
{
  # services = {
  #   redis = {
  #     enable = true;
  #   };
  # };

  # launchd.user.agents = {
  # mongodb = {
  #   serviceConfig = {
  #     # only start the service on demand
  #     KeepAlive = false;
  #     RunAtLoad = false;
  #   };
  # };
  #   postgresql = {
  #     serviceConfig = {
  #       # only start the service on demand
  #       KeepAlive = false;
  #       RunAtLoad = false;
  #     };
  # };
  # };

  # NB: The daemon is not used in version 3.1.0 of karabiner-driverkit
  launchd.daemons = {
    karabiner = {
      serviceConfig = {
        Label = "com.github.pqrs-org-Karabiner-DriverKit-VirtualHIDDevice";
        # ProcessType = "Interactive";
        Program = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
        RunAtLoad = true;
        # KeepAlive = true;
      };
    };
  };

  launchd.daemons = {
    kanata = {
      serviceConfig = {
        Label = "com.github.jtroo-kanata";
        ProgramArguments = [
          "/run/current-system/sw/bin/kanata"
          "-c"
          "${config.users.users.timotheos.home}/.dotfiles/modules/kanata/kanata.lsp"
        ];
        RunAtLoad = false;
        KeepAlive = {
          # this keeps the kanata daemon alive when the karabiner daemon is alive
          OtherJobEnabled = {
            "com.github.pqrs-org-Karabiner-DriverKit-VirtualHIDDevice" = true;
          };
        };
        StandardOutPath = "/var/log/kanata.log";
        StandardErrorPath = "/var/log/kanata.log";
      };
    };
  };

}
