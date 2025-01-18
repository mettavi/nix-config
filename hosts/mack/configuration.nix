{
  inputs,
  ...
}:
{
  networking.hostName = "mack";

  nixpkgs.hostPlatform = "x86_64-darwin";

  imports = [
    ../../hosts/mack/users.nix
    ../../common/shared
    ../../common/darwin
    ../../modules/sops/sops-system.nix
  ];

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}
