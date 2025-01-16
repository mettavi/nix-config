{
  inputs,
  ...
}:
{
  networking.hostName = "mack";

  imports = [
    ../../common/shared/default.nix
    ../../common/darwin/default.nix
    ../../modules/sops/sops-system.nix
  ];

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-darwin";

  ########### CONFIGURE SYSTEM USERS ############

  users.users.ta = rec {
    name = "timotheos";
    home = "/Users/${name}";
    # authorize remote login to host using personal ssh key
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../modules/secrets/timotheos/keys/id_ed25519.pub)
    ];
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

}
