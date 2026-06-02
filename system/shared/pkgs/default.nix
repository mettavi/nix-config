{ pkgs, ... }:
{
  npmGlobals = (pkgs.callPackage ./npm_globals { });
  zotero-addons = (pkgs.callPackage ./zotero-addons { });
}
