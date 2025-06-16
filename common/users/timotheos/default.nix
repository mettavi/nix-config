{
  username,
  ...
}:
{
  home = {
    username = "${username}";
    homeDirectory = "/Users/${username}";
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "23.11";
    # make programs use XDG directories whenever supported
    preferXdgDirectories = true;
  };


  # install the HTML manual and "home-manager-help" command
  manual.html.enable = true;

  imports = [
    ./dots.nix
    ./programs.nix
    ./services-home.nix
    ./sops-home.nix
    ./vscode.nix
    ./yazi.nix
    ./zsh.nix
  ];
}
