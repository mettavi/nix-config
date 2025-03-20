{ pkgs, ... }:
{
  karabiner-driverkit = ( pkgs.callPackage ./karabiner-driverkit { } );
  libation = ( pkgs.callPackage ./libation { } );
  goldendictng-gh = ( pkgs.callPackage ./goldendictng-gh { } );
}
