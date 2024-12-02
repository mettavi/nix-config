{
  lib,
  stdenv,
  fetchurl,
  # xar,
  # cpio,
}:

let
  pname = "karabiner-driverkit";
  versions = {
    darwin = "5.0.0";
  };
  hashes = {
    darwin = "sha256-hKi2gmIdtjl/ZaS7RPpkpSjb+7eT0259sbUUbrn5mMc=";
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

  libRoot = "Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice";
in
stdenv.mkDerivation {
  inherit pname meta;
  version = versions.darwin;

  src = fetchurl {
    url = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${versions.darwin}/Karabiner-DriverKit-VirtualHIDDevice-${versions.darwin}.pkg";
    hash = hashes.darwin;
  };

  # nativeBuildInputs = [
  #   xar
  #   cpio
  # ];

  # unpackPhase = ''
  #   xar -xf $src
  #   zcat < Payload | cpio -i
  # '';

  # unpack does not create a folder, so start from the current directory
  sourceRoot = ".";
  dontUnpack = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    # mkdir -p $out/Library/Application\ Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/{Applications,scripts/uninstall}
    cp -R ./Karabiner-DriverKit-VirtualHIDDevice-5.0.0.pkg $out/
    # cp -R "./Applications/.Karabiner-VirtualHIDDevice-Manager.app" "$out/Apps"
    # mkdir -p "$out/${libRoot}/Applications"
    # mkdir -p "$out/${libRoot}/scripts/uninstall"
    # cp -R "./${libRoot}/Applications/Karabiner-VirtualHIDDevice-Daemon.app" "$out/${libRoot}/Applications"
    # cp -R "./${libRoot}/scripts" "$out/${libRoot}"
    runHook postInstall
  '';

  # postInstall = ''
    # "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate"
    # sudo '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon'
  # '';
}
