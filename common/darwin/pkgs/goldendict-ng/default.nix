{
  lib,
  fetchurl,
  stdenvNoCC,
  undmg,
  nix-update-script,
}:

stdenvNoCC.mkDerivation rec {
  pname = "goldendict-ng";
  version = "25.02.0-Release.e895b18c";

  src = fetchurl {
    url = "https://github.com/xiaoyifang/goldendict-ng/releases/download/v${version}/GoldenDict-ng-25.02.0-Qt6.7.2-macOS-x86_64.dmg";
    hash = "sha256-gnu6HBbJk7UujJpHrHbZGLrTmXZenSEGR6nqoT5Iie8=";
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
    cp -pR "GoldenDict-ng.app" "$out/Applications"
    runHook postInstall
  '';

  meta = {
    description = "The Next Generation GoldenDict";
    homepage = "https://xiaoyifang.github.io/goldendict-ng/";
    changelog = "https://github.com/xiaoyifang/goldendict-ng/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ xiaoyifang ];
    mainProgram = "goldendict-ng";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
