{
  programs = {
    ssh = {
      # NB: There is no enable option for ssh
      # ensure ssh-agent is running
      startAgent = true;
    };
  };
}
