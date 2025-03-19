{ pkgs, ... }:
{
  karabiner-driverkit = ( pkgs.callPackage ./karabiner-driverkit { } );
  libation = ( pkgs.callPackage ./libation { } );
  goldendict-ng = ( pkgs.callPackage ./goldendict-ng { } );
}
