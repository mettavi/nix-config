{
  ensureNewerSourcesForZipFilesHook,
  fetchFromGitHub,
  lib,
  pkgs,
  python3,
  stdenvNoCC,
}:
{
  pname,
  version,
  hash,
  subdir ? pname, # the plugin's directory inside the monorepo, if it differs from pname
  zipName, # the exact .zip filename the build produces
  meta,
}:

stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "kiwidude68";
    repo = "calibre_plugins";
    rev = "refs/tags/${pname}-${version}";
    inherit hash;
  };

  nativeBuildInputs = [ ensureNewerSourcesForZipFilesHook ];

  buildPhase = ''
    runHook preBuild
    (cd ${subdir} && ${lib.getExe python3} ../common/build.py)
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out "${subdir}/${zipName}"
    runHook postInstall
  '';

  passthru = {
    pluginZip = zipName;
    updateScript = pkgs.nix-update-script {
      extraArgs = [
        "--file"
        ../../../../update.nix
      ];
    };
  };

  meta = {
    platforms = with lib.platforms; linux ++ darwin ++ windows;
    license = lib.licenses.gpl3Only;
  }
  // meta;
}
