{
  lib,
  pkgs,
  nix-update-script,
  stdenv,
  fetchurl,
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
    maintainers = with maintainers; [ mettavi ];
    platforms = [ "x86_64-darwin" ];
  };

in
stdenv.mkDerivation {
  inherit pname meta;
  # this is a required field (along with "pname") if not using the "name" field
  version = versions.darwin;

  src = fetchurl {
    url = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${versions.darwin}/Karabiner-DriverKit-VirtualHIDDevice-${versions.darwin}.pkg";
    hash = hashes.darwin;
  };

  # unpack does not create a folder, so start from the current directory
  sourceRoot = ".";
  dontUnpack = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir $out
    cp $src $out/Karabiner-DriverKit-VirtualHIDDevice-${versions.darwin}.pkg
  '';

  # check driver version and activation status: "systemextensionsctl list | rg Karabiner"
  # check package version: "defaults read /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/Info.plist CFBundleVersion"
  # logs are available in /Library/Application Support/org.pqrs/tmp/rootonly/ and /var/log/karabiner/
  postInstall = ''
    /usr/bin/installer -pkg "$out/Karabiner-DriverKit-VirtualHIDDevice-5.0.0.pkg" -target /
    "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" activate 
  '';

  passthru.updateScript = nix-update-script { };
}
