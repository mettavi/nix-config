{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "tmux-weather";
  version = "unstable-2024-09-16";

  src = fetchFromGitHub {
    owner = "aaronpowell";
    repo = "tmux-weather";
    rev = "829b7031952f1c27eaf08e06001861b66b4de81e";
    hash = "sha256-8vKB60tOSOpHlXfgeiYABtDCoF9ehdDDr2hAY0bhrcQ=";
  };

  meta = {
    description = "Display weather information in tmux status bar";
    homepage = "https://github.com/aaronpowell/tmux-weather";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mettavi ];
    mainProgram = "tmux-weather";
    platforms = lib.platforms.all;
  };
}
