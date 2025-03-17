{
  # there is also a overlays submodule included in the imports list
  nixpkgs.overlays = [
    (final: prev: {
      # install global npm packages that are not available in nixpkgs repo
      npmGlobals = final.callPackage ../../modules/npm_globals/node-packages-v18.nix {
        nodeEnv = final.callPackage ../../modules/npm_globals/node-env.nix {
          libtool = if final.stdenv.isDarwin then final.darwin.cctools else null;
        };
      };
      # Example for how to override the base version of ffmpeg
      # install ffmpeg with the non-free libfdk_aac codec
      # ffmpeg = prev.ffmpeg.override {
      #   withFdkAac =true;
      # };
    })
  ];
}
