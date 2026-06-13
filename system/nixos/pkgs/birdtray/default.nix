{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  nix-update-script,
  pkg-config,
  qt6,
  wrapGAppsHook3,
}:
stdenv.mkDerivation {
  pname = "birdtray";
  version = "1.12.4-dev";
  src = fetchFromGitHub {
    owner = "gyunaev";
    repo = "birdtray";
    rev = "7e35be6e3e59b252ded2eef32f7947b63b4028a9";
    hash = "sha256-RFK32dr2SGCXUsVRuqslLBsKqwwY1M86lGpgWUwUyec=";
  };

  buildInputs = with qt6; [
    qtbase
    qttools
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
    wrapGAppsHook3
  ];

  cmakeFlags = [
    # CMake 4 dropped support of versions lower than 3.5,
    # versions lower than 3.10 are deprecated.
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.10")
  ];

  # Wayland support is broken.
  # https://github.com/gyunaev/birdtray/issues/113#issuecomment-621742315
  qtWrapperArgs = [ "--set QT_QPA_PLATFORM xcb" ];

  meta = {
    description = "Mail system tray notification icon for Thunderbird";
    mainProgram = "birdtray";
    homepage = "https://github.com/gyunaev/birdtray";
    license = lib.licenses.gpl3Plus;
    maintainers =
      with lib.maintainers;
      [ Flakebi ]
      ++ [
        {
          email = "marcus@melange.works";
          github = "marcusjang";
          githubId = 10116562;
          name = "Marcus Jang";
        }
      ];
    platforms = lib.platforms.linux;
  };

  passthru.updateScript = nix-update-script { };
}
