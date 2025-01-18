{ user1, ...}:
{
  home = {
    username = "${user1}";
    homeDirectory = "/Users/${user1}";
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
