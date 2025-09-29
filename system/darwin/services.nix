{
  config,
  nix_repo,
  username,
  ...
}:
{
  services = {
    openssh.enable = true;
  };

  # NB: The daemon is not used in version 3.1.0 of karabiner-driverkit
  launchd.daemons = {
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
        #   # this keeps the kanata daemon alive when the karabiner daemon is alive
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
    postfix = {
      serviceConfig = {
        Label = "org.postfix.custom";
        Program = "/usr/libexec/postfix/master";
        ProgramArguments = [ "master" ];
        QueueDirectories = [ "/var/spool/postfix/maildrop" ];
        AbandonProcessGroup = true;
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };

}
