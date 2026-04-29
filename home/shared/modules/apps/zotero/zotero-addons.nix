{ pkgs, ... }:
let
  inherit (pkgs) lib callPackage makeOverridable;

  buildZoteroXpiAddon = makeOverridable (
    { stdenv ? pkgs.stdenv
    , fetchurl ? pkgs.fetchurl
    , pname
    , version
    , addonId
    , url
    , hash
    , meta
    , ...
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
  zotero-open-pdf = buildZoteroXpiAddon rec {
    pname = "zotero-open-pdf";
    version = "0.0.11";
    addonId = "open-pdf@iris-advies.com";

    url = "https://github.com/retorquere/zotero-open-pdf/releases/download/v${version}/zotero-open-pdf-${version}.xpi";
    hash = "sha256-j6S7SQncj99+XrLN76EjnaEZqrjZZwOWjVtaDV1kKYI=";

    meta = with lib; {
      homepage = "https://github.com/retorquere/zotero-open-pdf";
      # license unclear
      platforms = platforms.all;
    };
  };

  cita = buildZoteroXpiAddon rec {
    pname = "cita";
    version = "1.0.0-beta.7";
    addonId = "zotero-wikicite@wikidata.org";

    url = "https://github.com/diegodlh/zotero-cita/releases/download/v${version}/zotero-cita.xpi";
    hash = "sha256-/RcO+W1LXp938L7kM6Yues8YvyrihYI/UgyRB66Rn9Y=";

    meta = with lib; {
      homepage = "https://github.com/diegodlh/zotero-cita";
      license = [ licenses.gpl3 ];
      platforms = platforms.all;
    };
  };

  zotero-storage-scanner = buildZoteroXpiAddon rec {
    pname = "zotero-storage-scanner";
    version = "5.0.12";
    addonId = "storage-scanner@iris-advies.com";

    url = "https://github.com/retorquere/zotero-storage-scanner/releases/download/v${version}/zotero-storage-scanner-${version}.xpi";
    hash = "sha256-WGF3//sdZ8qk9IKOrgP7kbi7Yz5iRMXCbr2wQeXqpT8=";

    meta = with lib; {
      homepage = "https://github.com/retorquere/zotero-storage-scanner";
      # license unclear
      platforms = platforms.all;
    };
  };

  zotero-auto-index = buildZoteroXpiAddon rec {
    pname = "zotero-auto-index";
    version = "5.0.9";
    addonId = "auto-index@iris-advies.com";

    url = "https://github.com/retorquere/zotero-auto-index/releases/download/v${version}/zotero-auto-index-${version}.xpi";
    hash = "sha256-VmOZn+6g0KLCxkLafc+5DaTP9/Fvx32a9LUBD6NQ8MI=";

    meta = with lib; {
      homepage = "https://github.com/retorquere/zotero-auto-index";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotero-ocr = buildZoteroXpiAddon rec {
    pname = "zotero-ocr";
    version = "0.8.1";
    addonId = "zotero-ocr@bib.uni-mannheim.de";

    url = "https://github.com/UB-Mannheim/zotero-ocr/releases/download/${version}/zotero-ocr-${version}.xpi";
    hash = "sha256-NFVWvDdToOTGU+y1AeAKMg2vukmGKcTZ3CDhvYEEopM=";

    meta = with lib; {
      homepage = "https://github.com/UB-Mannheim/zotero-ocr";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotero-robustlinks = buildZoteroXpiAddon rec {
    pname = "zotero-robustlinks";
    version = "2.0.0-20220320145937";
    addonId = "zotero-robustlinks@mementoweb.org";

    url = "https://github.com/lanl/Zotero-Robust-Links-Extension/releases/download/v${version}/robustlinks.xpi";
    hash = "sha256-U4ZPhFP06YP8xXmx8p0lTUa0nDtZN3YyrCPxtgz7D0E=";

    meta = with lib; {
      homepage = "https://robustlinks.mementoweb.org/zotero/";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotero-abstract-cleaner = buildZoteroXpiAddon rec {
    pname = "zotero-abstract-cleaner";
    version = "0.1.6";
    addonId = "ZoteroAbstractCleaner@carter-tod.com";

    url = "https://github.com/dcartertod/zotero-plugins/releases/download/${version}/ZoteroAbstractCleaner.xpi";
    hash = "sha256-6ankwlieLLHiUPwhXptWwyomUaKCwEbVebTOWSbrLWs=";

    meta = with lib; {
      homepage = "https://github.com/dcartertod/zotero-plugins/tree/main/ZoteroAbstractCleaner";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotero-preview = buildZoteroXpiAddon rec {
    pname = "zotero-preview";
    version = "0.7.0";
    addonId = "zoteropreview@carter-tod.com";

    url = "https://github.com/dcartertod/zotero-plugins/releases/download/${version}/ZoteroPreview7.xpi";
    hash = "sha256-tLZIFNhhkMa0tO7HRJIiuEQnpLrNwLD1e96Wl/qXv4g=";

    meta = with lib; {
      homepage = "https://github.com/dcartertod/zotero-plugins/tree/main/ZoteroPreview";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotmoov = buildZoteroXpiAddon rec {
    pname = "zotmoov";
    version = "1.1.14";
    addonId = "zotmoov@wileyy.com";

    # TODO Remove "Beta" when the release is stable
    url = "https://github.com/wileyyugioh/zotmoov/releases/download/${version}/zotmoov-${version}-fx.xpi";
    hash = "sha256-Csp+cX7YouO8u7XZoY7gNnU5Z8V9dDe7+hxFKOqej3Q=";

    meta = with lib; {
      homepage = "https://github.com/wileyyugioh/zotmoov";
      license = [ licenses.gpl3 ];
      platforms = platforms.all;
    };
  };

  zotero-delitemwithatt = buildZoteroXpiAddon rec {
    pname = "zotero-delitemwithatt";
    version = "0.3.3";
    addonId = "delitemwithatt@redleaf.me";

    url = "https://github.com/redleafnew/delitemwithatt/releases/download/${version}/delitemwithatt.xpi";
    hash = "sha256-rUJrDIT1YaFXRYhqWegZXdYUHG9toQ6mbpFlVw1qM5w=";

    meta = with lib; {
      homepage = "https://github.com/redleafnew/delitemwithatt";
      license = [ licenses.agpl3Only ];
      platforms = platforms.all;
    };
  };

  scite-zotero = buildZoteroXpiAddon rec {
    pname = "scite-zotero";
    version = "2.0.2";
    addonId = "scite-zotero-plugin@scite.ai";

    url = "https://github.com/scitedotai/scite-zotero-plugin/releases/download/v${version}/scite-zotero-plugin-${version}.xpi";
    hash = "sha256-Etb8K9MrkzBGnQYDQeoexkV13VPPemIYNW8ubyrLlhc=";

    meta = with lib; {
      homepage = "https://github.com/scitedotai/scite-zotero-plugin";
      license = [ licenses.agpl3Only ];
      platforms = platforms.all;
    };
  };


  zotero-gpt = buildZoteroXpiAddon rec {
    pname = "zotero-gpt";
    version = "1.2.3";
    addonId = "zoterogpt@polygon.org";

    url = "https://github.com/MuiseDestiny/zotero-gpt/releases/download/${version}/zotero-gpt.xpi";
    hash = "sha256-qxl0/u3JJx1moXK7PcixTKeNNnJywwtkwgWYx5GHphM=";

    meta = with lib; {
      homepage = "https://github.com/MuiseDestiny/zotero-gpt";
      license = [ licenses.agpl3Only ];
      platforms = platforms.all;
    };
  };

  zotero-better-notes = buildZoteroXpiAddon rec {
    pname = "zotero-better-notes";
    version = "2.0.18";
    addonId = "Knowledge4Zotero@windingwind.com";

    url = "https://github.com/windingwind/zotero-better-notes/releases/download/v${version}/better-notes-for-zotero.xpi";
    hash = "sha256-02BMrJKyeQUJ9eafB8cDiu6ks4V+tcJecXt7Zv7F+Us=";

    meta = with lib; {
      homepage = "https://github.com/windingwind/zotero-better-notes";
      license = [ licenses.agpl3Only ];
      platforms = platforms.all;
    };
  };

  ai-research-assistant = buildZoteroXpiAddon rec {
    pname = "ai-research-assistant";
    version = "0.7.2";
    addonId = "aria@apex973.com";

    url = "https://github.com/lifan0127/ai-research-assistant/releases/download/v${version}/aria.xpi";
    hash = "sha256-ryZUt7gnAUayOCccuqwXp3VIMQYkY9gM+obQrmL2NPQ=";

    meta = with lib; {
      homepage = "https://github.com/lifan0127/ai-research-assistant";
      license = [ licenses.agpl3Only ];
      platforms = platforms.all;
    };
  };

}
