final: prev: {
  xpkgs = final.callPackage ../../shared/pkgs { };
  # Example for how to override the base version of ffmpeg
  # install ffmpeg with the non-free libfdk_aac codec
  # ffmpeg = prev.ffmpeg.override {
  #   withFdkAac =true;
  # };
}
