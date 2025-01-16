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
  # launchd.daemons = {
  #   karabiner-daemon = {
  #     serviceConfig = {
  #       Label = "com.mettavihari.karabiner-daemon";
  #       ProcessType = "Interactive";
  #       Program = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
  #       RunAtLoad = true;
  #       KeepAlive = true;
  #       StandardOutPath = "/Library/Logs/karabiner-driverkit/driverkit.out.log";
  #       StandardErrorPath = "/Library/Logs/karabiner-driverkit/driverkit.err.log";
  #     };
  #   };
  # };

  launchd.daemons = {
    kanata = {
      serviceConfig = {
        Label = "com.mettavihari.kanata";
        ProgramArguments = [
          "/usr/local/bin/kanata"
          "-c"
          "${config.users.users.ta.home}/.dotfiles/modules/kanata/kanata.lsp"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/Library/Logs/Kanata/kanata.out.log";
        StandardErrorPath = "/Library/Logs/Kanata/kanata.err.log";
      };
    };
  };

}
