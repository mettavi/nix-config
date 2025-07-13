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
        dst="$out/share/zotero/extensions/m5ubajjp.default"
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
    hash = "sha256-vfHRrTfLxyT47tEvxCg/pxf8ixH+vx2EkkWzmzg89jo=";

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
    hash = "sha256-02KFyczIGzMRraLivUYu9HfgfuWMA7srwCj9AK/VB4Q=";

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
    hash = "sha256-r8QHan0+5qj+1f4SDTODKMqH1XHD2Z+Tp31TUVqrv1o=";

    meta = with lib; {
      homepage = "https://github.com/wileyyugioh/zotmoov";
      license = [ licenses.gpl3 ];
      platforms = platforms.all;
    };
  };

  passthru.updateScript = nix-update-script { };
}
