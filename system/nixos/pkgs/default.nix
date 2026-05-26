{ pkgs, ... }:
{
  tipitaka_pali_reader = (pkgs.callPackage ./tipitaka-reader { });
}
