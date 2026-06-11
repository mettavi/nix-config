{ pkgs, ... }:
{
  tipitaka_pali_reader = (pkgs.callPackage ./tipitaka-reader { });
  birdtray = (pkgs.callPackage ./birdtray { });
}
