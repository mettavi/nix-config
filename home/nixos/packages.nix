{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wasistlos # Unofficial WhatsApp desktop gtk application for linux
  ];
}
