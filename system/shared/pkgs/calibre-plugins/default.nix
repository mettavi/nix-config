{ pkgs, ... }:
{
  extract-isbn = (pkgs.callPackage ./kiwidude/extract_isbn { });
}
