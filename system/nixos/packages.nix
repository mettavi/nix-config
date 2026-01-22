{ config, pkgs, ... }:
{
  environment.systemPackages =
    with pkgs;
    [
      bind # Domain name server with utilities like dig and nslookup
      cpuid # Linux tool to dump x86 CPUID information about the CPU
      # gcc, gnumake and unzip are required for nvim
      # GNU Compiler Collection (required for nvim treesitter)
      gcc
      # Tool to control the generation of non-source files from sources (required for neovim telescope-fzf)
      gnumake
      gparted # graphic disk partitioning tool
      libva-utils # utilities for VA-API (video acceleration API)
      lshw-gui # detailed hardware info (includes gui)
      # Icons of the Nix logo, in Freedesktop Icon Directory Layout
      nixos-icons
      pciutils # tools for working with pci devices
      # nodejs
      # python3
      systemctl-tui # Simple TUI for interacting with systemd services and their logs
      # Command line interface to the freedesktop.org trashcan
      trash-cli
      # Extraction utility
      # unzip
      unetbootin # Tool to create bootable live USB devices with iso images
      usbutils # tools for working with usb devices
    ]
    # prevent duplicate packages of ffmpeg (jellyfin requires its own version of ffmpeg)
    ++ lib.optionals (!config.services.jellyfin.enable) [
      ffmpeg
    ];
}
