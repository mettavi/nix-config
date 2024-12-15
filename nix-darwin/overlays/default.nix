{
  config,
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.overlays = [
    (final: prev: {
      # install global npm packages that are not available in nixpkgs repo
      npmGlobals = final.callPackage ../npm_globals/node-packages-v18.nix {
        nodeEnv = final.callPackage ../npm_globals/node-env.nix {
          libtool = if final.stdenv.isDarwin then final.darwin.cctools else null;
        };
      };
    })
    (import ./overlay-qtwebengine.nix)
  ];
}
