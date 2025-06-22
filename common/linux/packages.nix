{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Show battery status and other ACPI information (used for tmux catppuccin theme)
    acpi
    # gcc, gnumake and unzip are required for nvim
    # GNU Compiler Collection
    gcc
    # Tool to control the generation of non-source files from sources
    gnumake
    nodejs
    python3
    transmission_4-gtk
    # Extraction utility
    unzip
  ];
}
