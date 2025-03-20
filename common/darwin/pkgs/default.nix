{ pkgs, ... }:
{
  karabiner-driverkit = (pkgs.callPackage ./karabiner-driverkit { });
  # install more recent libation version than in nixpkgs
  libation-gh = (pkgs.callPackage ./libation-gh { });
  goldendictng-gh = (pkgs.callPackage ./goldendictng-gh { });
}
