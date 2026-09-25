{ pkgs, ... }:
{
  # npmGlobals = (pkgs.callPackage ./npm_globals { });
  calibrePlugins = (pkgs.callPackage ./calibre-plugins { });
  zotero-addons = (pkgs.callPackage ./zotero-addons { });
}
