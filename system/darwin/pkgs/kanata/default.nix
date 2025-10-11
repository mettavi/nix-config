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
  # this version requires karabiner-driverkit v.6.2.0
  version = "1.10.0-prerelease-2";

  src = fetchFromGitHub {
    owner = "jtroo";
    repo = "kanata";
    # the previous commit to this one fixed a bug that was making kanata unresponsive after system sleep
    # see https://github.com/jtroo/kanata/issues/1539 for details
    rev = "26640cacd9a5ea163505e6660d466b0b8a0791e3";
    hash = "sha256-aQDeMfkb6wjwQ40wP0XE2JcaOrHArvItVfB6QsmVpuc=";
  };

  cargoHash = "sha256-pEA1i7abdfBjAHwSAjwO4RKlmTMHgeDLBbbfzMbB2xg=";
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
