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
  getIcon = builtins.fetchurl {
    url = "file:///home/timotheos/.nix-config/system/nixos/pkgs/tipitaka-reader/logo-128.png";
    sha256 = "sha256:0hyk3nw70nyx0avkhxq8kxv1y24vmp29mq2bgpryxaxkz4fsr599";
  };

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

  passthru.updateScript = nix-update-script { };
}
