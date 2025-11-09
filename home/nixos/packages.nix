{ pkgs, ... }:
{
  home.packages = with pkgs; [
    switcheroo # App for converting (and resizing) images between different formats (uses imagemagick)
    wasistlos # Unofficial WhatsApp desktop application for linux
  ];
}
