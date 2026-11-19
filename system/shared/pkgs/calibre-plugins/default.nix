# See https://github.com/jwillikers/media-juggler/tree/main/overlays/calibre-plugins
# for examples of derivations for calibre plugins
{ pkgs, ... }:
{
  recurseForDerivations = true;

  acsm = (pkgs.callPackage ./acsm { });
  annotations = (pkgs.callPackage ./annotations { });
  extract-isbn = (pkgs.callPackage ./kiwidude/extract_isbn { });
}
