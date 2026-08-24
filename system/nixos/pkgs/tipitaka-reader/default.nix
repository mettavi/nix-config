{
  nix-update-script,
  pkgs,
  ...
}:
let
  pname = "tipitaka_pali_reader";
  version = "2.8.7+117";
  src = pkgs.fetchurl {
    url = "https://github.com/bksubhuti/tipitaka-pali-reader/releases/download/v${version}/tipitaka_pali_reader.AppImage";
    hash = "sha256-+caCya527FQ4EMuUrzFhC9FTNbn6uZgs25402ai/bIg=";
  };
  getIcon = ./logo-128.png;

  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
in
# this function creates a wrapped package 'tipitaka_pali_reader' to run the app directly (including via GUI)
# NB: the programs.appimage options instead allow to run the app with the 'appimage-run' command
pkgs.appimageTools.wrapType2 {
  inherit
    pname
    version
    src
    ;

  extraInstallCommands = # bash
    ''
      install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications/
      # gnome menus require a smaller app icon
      install -m 444 -D ${getIcon} $out/share/icons/hicolor/128x128/apps/${pname}.png
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Icon=logo' 'Icon=tipitaka_pali_reader'
    '';

  extraPkgs =
    pkgs: with pkgs; [
      libepoxy
      sqlite
    ];

  meta = {
    description = "A Pali Reading app made in Flutter";
    homepage = "https://github.com/bksubhuti/tipitaka-pali-reader";
    downloadPage = "https://github.com/bksubhuti/tipitaka-pali-reader/releases";
    # see the available values at https://github.com/NixOS/nixpkgs/blob/master/lib/licenses/licenses.nix
    platforms = [ "x86_64-linux" ];
  };

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex=^v(\\d+\\.\\d+\\.\\d+(?:\\+\\d+)?)$"
    ];
  };
}
