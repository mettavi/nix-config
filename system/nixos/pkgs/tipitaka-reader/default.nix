{
  nix-update-script,
  pkgs,
  ...
}:
let
  pname = "tipitaka_pali_reader";
  version = "2.7.8+108";
  src = pkgs.fetchurl {
    url = "https://github.com/bksubhuti/tipitaka-pali-reader/releases/download/v${version}/tipitaka_pali_reader.AppImage";
    hash = "sha256-R4j0iMIGmPY7+Gzd0MbMWX1MFyfVLE4cemy7Gh6mr58=";
  };

  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
in
pkgs.appimageTools.wrapType2 {
  inherit
    pname
    version
    src
    ;
  pkgs = pkgs;
  extraInstallCommands = # bash
    ''
      install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications/
      # substituteInPlace $out/share/applications/${pname}.desktop \
      #   --replace-fail 'Exec=${pname}' 'Exec=${pname}'
      install -m 444 -D ${appimageContents}/logo.png $out/share/icons/hicolor/1024x1024/apps/${pname}.png

      # unless linked, the binary is placed in $out/bin/name-someVersion
      # ln -s $out/bin/${pname}-${version} $out/bin/${pname}
    '';

  # extraBwrapArgs = [
  #   "--bind-try /etc/nixos/ /etc/nixos/"
  # ];

  # vscode likes to kill the parent so that the
  # gui application isn't attached to the terminal session

  # dieWithParent = false;

  # extraPkgs =
  #   pkgs: with pkgs; [
  # unzip
  # autoPatchelfHook
  # asar
  # # override doesn't preserve splicing https://github.com/NixOS/nixpkgs/issues/132651
  # (buildPackages.wrapGAppsHook3.override { inherit (buildPackages) makeWrapper; })
  # ];

  meta = {
    description = "A Pali Reading app made in Flutter";
    homepage = "https://github.com/bksubhuti/tipitaka-pali-reader";
    downloadPage = "https://github.com/bksubhuti/tipitaka-pali-reader/releases";
    # see the available values at https://github.com/NixOS/nixpkgs/blob/master/lib/licenses/licenses.nix
    platforms = [ "x86_64-linux" ];
  };

  passthru.updateScript = nix-update-script { };
}
