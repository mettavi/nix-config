{ inputs, ... }:
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];
  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    # enableRosetta = true;

    # User owning the Homebrew prefix
    user = "timotheos";

    # Optional: Declarative tap management
    # You only need to add taps as Flake inputs if you set nix-homebrew.mutableTaps = false.
    taps = {
      # the repo part of all taps should have "homebrew-" prepended
      # "homebrew/homebrew-core" = inputs.homebrew-core;
      # "homebrew/homebrew-cask" = inputs.homebrew-cask;
      # "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
    };

    # Optional: Enable fully-declarative tap management
    #
    # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
    # mutableTaps = false;
  };
}
