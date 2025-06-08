{ user1, ... }:
{
  home = {
    username = "${user1}";
    homeDirectory = "/Users/${user1}";
    stateVersion = "23.11";
    # make programs use XDG directories whenever supported
    preferXdgDirectories = true;
  };

  nix = {
    # by default this will run at midnight on Mondays (as per systemd.time(7))
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
  home.sessionVariables = {
    # prevent nh from checking for flakes "experimental features" (which it can't read from determinate nix.custom.conf)
    NH_NO_CHECKS = "1";
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
