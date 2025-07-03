{
  nix = {
    # enable automatic garbage collection and store optimisation 
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d"; # Delete generations older than 30 days
      persistent = true;
    };
    optimise = {
      automatic = true;
      dates = "02:15";
    };
  };
}
