{ pkgs, ... }:
{
  karabiner-driverkit = ( pkgs.callPackage ./karabiner-driverkit { } );
}
