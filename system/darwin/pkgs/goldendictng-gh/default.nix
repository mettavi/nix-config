{
  lib,
  nix-update-script,
  fetchurl,
  stdenvNoCC,
  undmg,
}:
let
  pname = "goldendictng-gh";
  version = "25.06.0-Release.8a87a79b";
  shortver = builtins.substring 0 7 version;
  src = fetchurl {
    url = "https://github.com/xiaoyifang/goldendict-ng/releases/download/v${version}/GoldenDict-ng-${shortver}-Qt6.7.2-macOS-x86_64.dmg";
    hash = "sha256-MGor5nT1np9IA/t2lhSaUtNpAJOoikTkeyiR3YDVQHU=";
  };
in
stdenvNoCC.mkDerivation rec {
  inherit
    pname
    src
    version
    ;

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

  # update script does not work on this src.url format
  passthru.updateScript = nix-update-script { };

  meta = {
    description = "The Next Generation GoldenDict";
    homepage = "https://xiaoyifang.github.io/goldendict-ng/";
    changelog = "https://github.com/xiaoyifang/goldendict-ng/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      slbtty
      michojel
    ];
    mainProgram = "goldendict-ng";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
