{
  pkgs ? import <nixpkgs> { },
}:
pkgs.stdenv.mkDerivation {
  name = "kanata";
  src = pkgs.fetchurl {
    url = "https://github.com/jtroo/kanata/releases/download/v1.7.0/kanata_macos_x86_64";
    sha256 = "e3f0d99e512a84c5cae1f63e71c07ecdbff66dc89b053aba0abb4f9dee0cadc0";
  };
  phases = [
    "installPhase"
    "patchPhase"
  ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/kanata
    chmod +x $out/bin/kanata
  '';
  postInstall = ''
    ln -s $out/bin/kanata /usr/local/bin/kanata
  '';
}
