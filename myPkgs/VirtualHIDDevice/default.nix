{ lib
, stdenv
, fetchurl
, xar
, cpio
, makeWrapper
}:

let
  pname = "karabiner-driverkit";
  versions = {
    darwin = "5.0.0";
  };
  hashes = {
    darwin = "sha256-sOnPB832RNPS5jhLZ0FmqYA+tsO44Rg0lEcyCsw/tok=";
  };
  meta = with lib; {
    description = "This project implements a virtual keyboard and virtual mouse using DriverKit on macOS.";
    homepage = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice";
    downloadPage = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.publicDomain;
    maintainers = with maintainers; [ tekezo ];
    platforms = [ "x86_64-darwin" ];
    mainProgram = ".Karabiner-VirtualHIDDevice-Manager.app";
  };

  appName = "Teams.app";
in
stdenv.mkDerivation {
  inherit pname meta;
  version = versions.darwin;

  src = fetchurl {
    url = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${versions.darwin}/Karabiner-DriverKit-VirtualHIDDevice-${versions.darwin}.pkg";
    hash = hashes.darwin;
  };

  nativeBuildInputs = [ xar cpio makeWrapper ];

  unpackPhase = ''
    xar -xf $src
    zcat < Teams_osx_app.pkg/Payload | cpio -i
  '';

  sourceRoot = "Microsoft\ Teams.app";
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{Applications/${appName},bin}
    cp -R . $out/Applications/${appName}
    makeWrapper $out/Applications/${appName}/Contents/MacOS/Teams $out/bin/teams
    runHook postInstall
  '';
}
