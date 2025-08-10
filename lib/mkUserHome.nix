{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ../home/shared/dots.nix
    ../home/shared/programs.nix
    ../home/shared/sops-home.nix
    ../home/shared/modules
    ../home/darwin
    ../home/nixos
    ../users/${username}
  ];

  home = {
    username = "${username}";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
    # make programs use XDG directories whenever supported
    preferXdgDirectories = true;
  };
}
