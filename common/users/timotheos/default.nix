{
  pkgs,
  username,
  ...
}:
{
  home = {
    username = "${username}";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
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
  ];
}
