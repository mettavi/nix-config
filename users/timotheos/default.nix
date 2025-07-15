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
    ../../home/shared/dots.nix
    ../../home/shared/programs.nix
    ../../home/shared/services-home.nix
    ../../home/shared/sops-home.nix
  ];
}
