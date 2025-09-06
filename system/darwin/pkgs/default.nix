{ pkgs, ... }:
{
  goldendictng-gh = (pkgs.callPackage ./goldendictng-gh { });
  karabiner-driverkit = (pkgs.callPackage ./karabiner-driverkit { });
  # libation-gh = (pkgs.callPackage ./libation-gh { });
  stacher = (pkgs.callPackage ./stacher { });
}
