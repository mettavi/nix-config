{ pkgs, ... }:
{
  tipitaka_pali_reader = (pkgs.callPackage ./tipitaka-reader { });
  birdtray = (pkgs.callPackage ./birdtray { });
  pia-wg-config = (pkgs.callPackage ./pia-wg-conf { });
  pia-wg-config2 = (pkgs.callPackage ./pia-wg-conf2 { });
}
