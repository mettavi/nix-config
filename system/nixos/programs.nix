{
  programs = {
    ssh = {
      # NB: There is no enable option for ssh
      # ensure ssh-agent is running
      # NB: Not required if the keychain utility is installed
      # startAgent = true;
    };
  };
}
