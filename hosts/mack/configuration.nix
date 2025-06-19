{
  inputs,
  ...
}:
{
  networking.hostName = "mack";

  # the determinate insaller was used, so nix settings are managed in /etc/nix/nix.conf and nix.custom.conf
  nix.enable = false;

  programs.zsh = {
    completionInit = ''
      # enable auto-completion for determinate nixd
      eval "$(determinate-nixd completion zsh)"
    '';
  };
  nixpkgs.hostPlatform = "x86_64-darwin";

  imports = [
    ./users.nix
    ../../common/shared
    ../../common/darwin
  ];

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog and https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = 5;
}
