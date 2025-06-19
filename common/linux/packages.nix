{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # gcc and gnumake are required for nvim
    # GNU Compiler Collection
    gcc
    # Tool to control the generation of non-source files from sources
    gnumake
  ];
}
