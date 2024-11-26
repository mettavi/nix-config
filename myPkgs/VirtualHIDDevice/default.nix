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
    darwin = "3.1.0";
  };
  hashes = {
    darwin = "replace_me";
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
    url = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v3.1.0/Karabiner-DriverKit-VirtualHIDDevice-3.1.0.pkg";
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
