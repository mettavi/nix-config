{
  ensureNewerSourcesForZipFilesHook,
  fetchFromGitHub,
  lib,
  pkgs,
  python3,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "extract_isbn";
  version = "1.6.6";

  src = fetchFromGitHub {
    owner = "kiwidude68";
    repo = "calibre_plugins";
    rev = "refs/tags/extract_isbn-${version}";
    hash = "sha256-SJc6CDdg1Da8SCLv4AeSkxZOcH26AHZ1xa4UEjXN8zM=";
  };

  nativeBuildInputs = [ ensureNewerSourcesForZipFilesHook ];

  buildPhase = ''
    runHook preBuild
    (cd extract_isbn && ${lib.getExe python3} ../common/build.py)
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out "extract_isbn/Extract ISBN.zip"
    runHook postInstall
  '';

  passthru = {
    pluginZip = "Extract ISBN.zip";
    updateScript = pkgs.nix-update-script {
      extraArgs = [
        "--file"
        ../../../../update.nix
      ];
    };
  };

  meta = {
    description = "This plugin can be used to try to find the ISBN for a book using the text within a book format";
    homepage = "https://github.com/kiwidude68/calibre_plugins/tree/main/extract_isbn";
    changelog = "https://github.com/kiwidude68/calibre_plugins/releases/tag/extract_isbn-v${version}";
    platforms = with lib.platforms; linux ++ darwin ++ windows;
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ mettavi ];
  };
}
