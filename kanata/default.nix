{
  lib,
  rustPlatform,
  fetchFromGitHub,
  stdenv,
  darwin,
}:

rustPlatform.buildRustPackage rec {
  pname = "kanata";
  version = "unstable-2024-11-25";

  src = fetchFromGitHub {
    owner = "jtroo";
    repo = "kanata";
    rev = "89235ac";
    hash = "sha256-fDB6Vrgr+nk+4gvuvqUP2ODQgsZVkmoDetbU9+Y654g=";
  };

  cargoHash = "sha256-Zra41zL/Awjd7H2tEJZa8tJ4r3EZYYD+DOhH+Lehlrw=";

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.CoreGraphics
  ];

  meta = {
    description = "Improve keyboard comfort and usability with advanced customization";
    homepage = "https://github.com/jtroo/kanata";
    license = lib.licenses.unfree; # FIXME: nix-init did not find a license
    maintainers = with lib.maintainers; [ ];
    mainProgram = "kanata";
  };
}
