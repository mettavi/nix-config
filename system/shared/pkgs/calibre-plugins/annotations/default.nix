{
  ensureNewerSourcesForZipFilesHook,
  fetchFromGitHub,
  lib,
  pkgs,
  stdenvNoCC,
  zip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "annotations";
  version = "1.17.17";

  src = fetchFromGitHub {
    owner = "calibre-annotations";
    repo = "Annotations";
    rev = "v${version}";
    hash = "sha256-a/XOrfnfj4M/qVdQwsygl0Q8qAToEk4jvb1fwy9MfE8=";
  };

  nativeBuildInputs = [
    ensureNewerSourcesForZipFilesHook
    zip
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out

    excludes=("readers/_*")
    while IFS= read -r pattern || [ -n "$pattern" ]; do
      [ -z "$pattern" ] && continue
      case "$pattern" in
        */) pattern="''${pattern}*" ;;
      esac
      excludes+=("$pattern")
    done < .distignore

    zip -r "$out/Annotations.zip" . -x "''${excludes[@]}"
    runHook postInstall
  '';

  passthru = {
    pluginZip = "Annotations.zip";
    updateScript = pkgs.nix-update-script {
      extraArgs = [
        "--file"
        ../../../../../update.nix
      ];
    };
  };

  meta = {
    description = "Import and search annotations/highlights from ebook readers into calibre";
    homepage = "https://github.com/calibre-annotations/Annotations";
    changelog = "https://github.com/calibre-annotations/Annotations/releases/tag/v${version}";
    platforms = with lib.platforms; linux ++ darwin ++ windows;
    license = lib.licenses.gpl3Only; # per source headers; repo has no separate LICENSE file
    maintainers = with lib.maintainers; [ mettavi ];
  };
}
