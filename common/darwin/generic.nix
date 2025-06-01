{
  inputs,
  ...
}:
{
  nix = {
    # run nix-collect-garbage automatically 
    # by default this will run each Sunday at (or after is the system is down) 3:15 am
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    nixPath = [
      # this ensures $NIX_PATH is set to an immutable location in the nix-store
      # "nixpkgs-overlays=$HOME/.dotfiles/common/darwin/overlays"
      "darwin=${inputs.nix-darwin}"
    ];
    # by default this will run each Sunday at (or after is the system is down) 4:15 am
    optimise = {
      automatic = true;
    };
  };
  nixpkgs = {
    overlays = [ (import ../overlays/darwin/default.nix) ];
  };
}
