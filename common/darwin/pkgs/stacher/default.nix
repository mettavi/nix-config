{
  lib,
  fetchurl,
  stdenvNoCC,
  undmg,
  nix-update-script,
}:

stdenvNoCC.mkDerivation rec {
  pname = "stacher";
  version = "7.0.16";

  src = fetchurl {
    url = "https://s7-releases.stacher-cloud.com/s7-releases/Stacher_Setup_${version}_x64.dmg";
    hash = "sha256-EUKZeq8YH7w4nBfTq9RABhfZMlUUQMDVvmE8fb9Q5rE=";
  };

  nativeBuildInputs = [
    undmg
  ];

  sourceRoot = ".";
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    # Install the application
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -pR "Stacher7.app" "$out/Applications"
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A modern GUI for yt-dlp";
    homepage = "https://stacher.io/";
    license = lib.licenses.cc-by-nc-nd-40;
    mainProgram = "Stacher7";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
