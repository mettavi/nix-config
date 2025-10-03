{
  apple-sdk_13,
  darwinMinVersionHook,
  fetchFromGitHub,
  lib,
  rustPlatform,
  stdenv,
  versionCheckHook,
  withCmd ? false,
  writeShellScriptBin,
}:

rustPlatform.buildRustPackage {
  pname = "kanata-head";
  version = "1.10.0-prerelease-1";

  src = fetchFromGitHub {
    owner = "jtroo";
    repo = "kanata";
    # the previous commit to this one fixed a bug that was making kanata unresponsive after system sleep
    # see https://github.com/jtroo/kanata/issues/1539 for details
    rev = "25193104aad589e6df4a4ec700750ff8e18d27bd";
    hash = "sha256-vnz3/GkQm3PE3mA97jLbvVouQot6tOylpdJXRfpSFrA=";
  };

  cargoHash = "sha256-cumyuHwBVcvMfPJqrgzFMoP5m5AKa4wE7SRabxfnGC8=";
  buildType = "debug";

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_13
    (darwinMinVersionHook "13.0")
  ];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    (writeShellScriptBin "sw_vers" ''
      echo 'ProductVersion: 13.0'
    '')
  ];

  buildFeatures = lib.optional withCmd "cmd";

  postInstall = ''
    install -Dm 444 assets/kanata-icon.svg $out/share/icons/hicolor/scalable/apps/kanata.svg
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  meta = {
    description = "Improve keyboard comfort and usability with advanced customization";
    homepage = "https://github.com/jtroo/kanata";
    license = lib.licenses.lgpl3;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "kanata";
  };
}
