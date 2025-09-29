{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # gcc, gnumake and unzip are required for nvim
    # GNU Compiler Collection (required for nvim treesitter)
    gcc
    # Tool to control the generation of non-source files from sources (required for neovim telescope-fzf)
    gnumake
    # nodejs
    # python3
    # Command line interface to the freedesktop.org trashcan
    trash-cli
    # Extraction utility
    # unzip
    # Tool to access the X clipboard from a console application
    # Required for clipboard integration with neovim
    xclip
  ];
}
