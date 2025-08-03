{ pkgs, ... }:
{
  tmux-weather = (pkgs.callPackage ./tmux-weather { });
}
