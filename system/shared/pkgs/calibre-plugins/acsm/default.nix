{
  stdenv,
  fetchFromGitHub,
  fetchzip,
  lib,
  openssl,
  pkgsCross,
  zip,
  unzip,
}:
let
  oscrypto = stdenv.mkDerivation {
    pname = "oscrypto";
    version = "1.3.0";
    src = fetchzip {
      url = "https://github.com/Leseratte10/acsm-calibre-plugin/releases/download/config/oscrypto_1.3.0_fork_2023-12-19.zip";
      hash = "sha256-LuPodbEpPMLsFqtuogcQtcj1LSG/7E+Q7TsLeCCKI/E=";
    };
    doCheck = false;
    postPatch = ''
      for file in oscrypto/_openssl/_libcrypto_c{ffi,types}.py; do
        substituteInPlace $file \
          --replace-fail "get_library('crypto', 'libcrypto.dylib', '42')" "'${openssl.out}/lib/libcrypto${stdenv.hostPlatform.extensions.sharedLibrary}'"
      done
      for file in oscrypto/_openssl/_libssl_c{ffi,types}.py; do
        substituteInPlace $file \
          --replace-fail "get_library('ssl', 'libssl', '44')" "'${openssl.out}/lib/libssl${stdenv.hostPlatform.extensions.sharedLibrary}'"
      done
    '';
    nativeBuildInputs = [ zip ];
    installPhase = "zip -r $out oscrypto";
  };

  asn1crypto = stdenv.mkDerivation {
    pname = "asn1crypto";
    version = "1.5.1";
    src = fetchzip {
      url = "https://github.com/Leseratte10/acsm-calibre-plugin/releases/download/config/asn1crypto_1.5.1.zip";
      hash = "sha256-HKOpZnBb34oYjgruO+KQhU4j5oTuT3c9ABgONW3lmiM=";
    };
    doCheck = false;
    nativeBuildInputs = [ zip ];
    installPhase = "zip -r $out asn1crypto";
  };
in
stdenv.mkDerivation rec {
  pname = "acsm-calibre-plugin";
  version = "0.1.0-unstable-2025-xx-xx"; # match whatever rev you pin

  src = fetchFromGitHub {
    owner = "nydragon"; # or "Leseratte10" if you'd rather track upstream directly
    repo = "acsm-calibre-plugin";
    rev = "80460ec79a0dea7135937b3e4f8228d1ca9dd167";
    hash = "sha256-UEu7gWt+p2V5NcCGHRgymz4EIb8N/xD3vWWXjBLWgTA=";
  };

  nativeBuildInputs = [
    pkgsCross.mingw32.buildPackages.gcc
    pkgsCross.mingwW64.buildPackages.gcc
    zip
    unzip
  ];
  buildInputs = [ openssl ];

  postPatch = ''
    substituteInPlace ./calibre-plugin/__init__.py \
      --replace-fail 'libcrypto_path = os.getenv("ACSM_LIBCRYPTO", None)' 'libcrypto_path = os.getenv("ACSM_LIBCRYPTO", "${openssl.out}/lib/libcrypto.so")' \
      --replace-fail 'libssl_path = os.getenv("ACSM_LIBSSL", None)' 'libssl_path = os.getenv("ACSM_LIBSSL", "${openssl.out}/lib/libssl.so")'
  '';

  buildPhase = ''
    runHook preBuild
    unzip ${asn1crypto} -d calibre-plugin/
    unzip ${oscrypto} -d calibre-plugin/
    bash ./bundle_calibre_plugin.sh
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out calibre-plugin.zip
    runHook postInstall
  '';

  passthru.pluginZip = "calibre-plugin.zip";

  meta = {
    description = "Calibre plugin for ACSM->EPUB and ACSM->PDF conversion without Adobe Digital Editions";
    homepage = "https://github.com/Leseratte10/acsm-calibre-plugin";
    platforms = with lib.platforms; linux ++ darwin ++ windows;
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ mettavi ];
  };
}
