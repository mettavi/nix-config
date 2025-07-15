{
  lib,
  rustPlatform,
  fetchFromGitHub,
  stdenv,
  darwin,
}:

rustPlatform.buildRustPackage rec {
  pname = "kanata";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "jtroo";
    repo = "kanata";
    rev = "v${version}";
    hash = "sha256-cG9so0x0y8CbTxLOxSQwn5vG72KxHJzzTIH4lQA4MvE=";
  };

  cargoHash = "sha256-WycyxpSc56DMwrvE/rYg5tv0BKIE59KpSFE+1FZPTQw=";
  buildType = "debug";
  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.CoreGraphics
  ];

  meta = {
    description = "Improve keyboard comfort and usability with advanced customization";
    homepage = "https://github.com/jtroo/kanata";
    license = lib.licenses.lgpl3;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "kanata";
  };
}
