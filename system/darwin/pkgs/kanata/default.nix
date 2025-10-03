{
  lib,
  rustPlatform,
  fetchFromGitHub,
  stdenv,
  darwin,
}:

rustPlatform.buildRustPackage {
  pname = "kanata-head";
  version = "unstable-2025-10-02";

  src = fetchFromGitHub {
    owner = "jtroo";
    repo = "kanata";
    # the previous commit to this one fixed a bug that was making kanata unresponsive after system sleep
    # see https://github.com/jtroo/kanata/issues/1539 for details
    rev = "25193104aad589e6df4a4ec700750ff8e18d27bd";
    hash = "sha256-vnz3/GkQm3PE3mA97jLbvVouQot6tOylpdJXRfpSFrA=";
  };

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
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
