{
  lib,
  nix-update-script,
  stdenvNoCC,
  fetchzip,
}:

let
  pname = "libation-gh";
  versions = {
    darwin = "12.4.3";
  };
  hashes = {
    darwin = "sha256-avzFQKrR31gy8b7xuGXAJfzHdlZHZvMNh/dAuzWaYRA=";
  };
  meta = with lib; {
    description = "Audible audiobook manager";
    homepage = "https://github.com/rmcrackan/Libation";
    downloadPage = "https://github.com/rmcrackan/Libation/releases";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.publicDomain;
    maintainers = with maintainers; [ tomasajt ];
    platforms = [ "x86_64-darwin" ];
  };

in
stdenvNoCC.mkDerivation {
  inherit pname meta;
  version = versions.darwin;

  src = fetchzip {
    url = "https://github.com/rmcrackan/Libation/releases/download/v${versions.darwin}/Libation.${versions.darwin}-macOS-chardonnay-x64.tgz";
    hash = hashes.darwin;
    # disable this as the archive already unpacks into the root
    stripRoot = false;
  };

  # unpack does not create a folder, so start from the current directory
  sourceRoot = ".";
  dontUnpack = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -pR $src/Libation.app $out/Applications
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };
}
