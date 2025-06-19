{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # gcc, gnumake and unzip are required for nvim
    # GNU Compiler Collection
    gcc
    # Tool to control the generation of non-source files from sources
    gnumake
    nodejs
    python3
    # Extraction utility
    unzip
  ];
}
