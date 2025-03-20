{ pkgs, ... }:
{
  karabiner-driverkit = ( pkgs.callPackage ./karabiner-driverkit { } );
  libation-gh = ( pkgs.callPackage ./libation-gh { } );
  goldendictng-gh = ( pkgs.callPackage ./goldendictng-gh { } );
}
