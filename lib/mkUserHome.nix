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
    # username and home are set automatically when using home-manager as a system module
    # username = "some_user";
    # homeDirectory = if pkgs.stdenv.isDarwin then "/Users/some_user" else "/home/some_user";
    # make programs use XDG directories whenever supported
    preferXdgDirectories = true;
  };
}
