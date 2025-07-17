{

  # install the HTML manual and "home-manager-help" command
  manual.html.enable = true;

  nyx = {
    modules = {
      shell = {
        bash.enable = true;
        nh.enable = true;
        tmux.enable = true;
        yazi.enable = true;
      };
    };
  };
}
