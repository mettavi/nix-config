{ pkgs, ... }:
{
  bitwarden-cli = (pkgs.callPackage ./bitwarden-cli { });
  npmGlobals = (pkgs.callPackage ./npm_globals { });
  zotero-addons = (pkgs.callPackage ./zotero-addons { });
}
