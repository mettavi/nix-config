{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # to get authentication-related functionality, currently this cannot be installed by home-manager
    # see https://github.com/NixOS/nixpkgs/pull/339384#issuecomment-2372065297
    bitwarden-desktop
    # gcc, gnumake and unzip are required for nvim
    # GNU Compiler Collection (required for nvim treesitter)
    gcc
    # Tool to control the generation of non-source files from sources (required for neovim telescope-fzf)
    gnumake
    gparted # graphic disk partitioning tool
    lshw-gui # detailed hardware info (includes gui)
    # Icons of the Nix logo, in Freedesktop Icon Directory Layout
    nixos-icons
    pciutils # tools for working with pci devices
    # nodejs
    # python3
    # Command line interface to the freedesktop.org trashcan
    trash-cli
    # Extraction utility
    # unzip
    usbutils # tools for working with usb devices
    # Tool to access the X clipboard from a console application
    # Required for clipboard integration with neovim
    xclip
  ];
}
