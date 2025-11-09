{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wasistlos # Unofficial WhatsApp desktop application for linux
  ];
}
