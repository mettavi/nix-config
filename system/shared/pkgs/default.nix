{ pkgs, ... }:
{
  # npmGlobals = (pkgs.callPackage ./npm_globals { });
  calibrePlugins = (pkgs.callPackage ./calibre-plugins { });
  zoteroAddons = (pkgs.callPackage ./zotero-addons { });
}
