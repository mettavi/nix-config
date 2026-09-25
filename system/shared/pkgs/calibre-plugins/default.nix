{ pkgs, ... }:
{
  extract-isbn = (pkgs.callPackage ./extract_isbn { });
}
