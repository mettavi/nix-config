{
  lib,
  pkgs,
  username,
  ...
}:
{
  imports =
    [
      ../home/shared/modules
      ../home/shared/dots.nix
      ../home/shared/programs.nix
      ../home/shared/services-home.nix
      ../home/shared/sops-home.nix
      ../users/${username}
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [ ../home/darwin/darwin.nix ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [ ../home/nixos/xfce.nix ];
  home = {
    username = "${username}";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
    # make programs use XDG directories whenever supported
    preferXdgDirectories = true;
  };
}
