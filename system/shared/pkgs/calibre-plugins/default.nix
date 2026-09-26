{ pkgs, ... }:
{
  annotations = (pkgs.callPackage ./annotations { });
  extract-isbn = (pkgs.callPackage ./kiwidude/extract_isbn { });
}
