{ pkgs, ... }:
{
  goldendictng-gh = (pkgs.callPackage ./goldendictng-gh { });
  # install from gh commit to get recent bugfix ASAP
  kanata-head = (pkgs.callPackage ./kanata { });
  karabiner-driverkit = (pkgs.callPackage ./karabiner-driverkit { });
  # libation-gh = (pkgs.callPackage ./libation-gh { });
  stacher = (pkgs.callPackage ./stacher { });
}
