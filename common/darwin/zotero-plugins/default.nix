{ nix-update-script, pkgs, ... }:
let
  inherit (pkgs) lib makeOverridable;

  buildZoteroXpiAddon = makeOverridable (
    {
      stdenv ? pkgs.stdenv,
      fetchurl ? pkgs.fetchurl,
      pname,
      version,
      addonId,
      url,
      hash,
      meta,
      ...
    }:
    stdenv.mkDerivation {
      name = "${pname}-${version}";

      inherit meta;

      src = fetchurl { inherit url hash; };

      preferLocalBuild = true;
      allowSubstitutes = true;

      buildCommand = ''
        dst="$out/share/zotero/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    }
  );
in
{
  betterbibtex = buildZoteroXpiAddon rec {
    pname = "zotero-better-bibtex";
    version = "7.0.38";
    addonId = "better-bibtex@iris-advies.com";

    url = "https://github.com/retorquere/zotero-better-bibtex/releases/download/v${version}/zotero-better-bibtex-${version}.xpi";
    hash = "";

    meta = with lib; {
      homepage = "https://github.com/retorquere/zotero-better-bibtex";
      license = [ licenses.mit ];
      platforms = platforms.all;
    };
  };

  zotero-addons = buildZoteroXpiAddon rec {
    pname = "zotero-addons";
    version = "2.1.1";
    addonId = "zoteroAddons@ytshen.com";

    url = "https://github.com/wileyyugioh/zotmoov/releases/download/V${version}/zotero-addons.xpi";
    hash = "";

    meta = with lib; {
      homepage = "https://github.com/syt2/zotero-addons";
      license = [ licenses.agpl3Plus ];
      platforms = platforms.all;
    };
  };

  zotmoov = buildZoteroXpiAddon rec {
    pname = "zotmoov";
    version = "1.1.14";
    addonId = "zotmoov@wileyy.com";

    url = "https://github.com/wileyyugioh/zotmoov/releases/download/${version}/zotmoov-${version}-fx.xpi";
    hash = "sha256-Csp+cX7YouO8u7XZoY7gNnU5Z8V9dDe7+hxFKOqej3Q=";

    meta = with lib; {
      homepage = "https://github.com/wileyyugioh/zotmoov";
      license = [ licenses.gpl3 ];
      platforms = platforms.all;
    };
  };

  passthru.updateScript = nix-update-script { };
}
