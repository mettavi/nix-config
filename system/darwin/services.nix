{
  services = {
    openssh.enable = true;
  };

  launchd.daemons = {
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
