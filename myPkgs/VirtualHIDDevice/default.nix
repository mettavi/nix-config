{
  lib,
  stdenv,
  fetchurl,
  xar,
  cpio,
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
  };

in
stdenv.mkDerivation {
  inherit pname meta;
  version = versions.darwin;

  src = fetchurl {
    url = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${versions.darwin}/Karabiner-DriverKit-VirtualHIDDevice-${versions.darwin}.pkg";
    hash = hashes.darwin;
  };

  nativeBuildInputs = [
    xar
    cpio
    makeWrapper
  ];

  unpackPhase = ''
    xar -xf $src
    zcat < Payload | cpio -i
  '';

  # unpack does not create a folder, so start from the current directory
  sourceRoot = ".";
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    mkdir -p "$out/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/{Applications,scripts/uninstall}"
    cp -R . $out
    runHook postInstall
    "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate"
    sudo '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon'
  '';
}
