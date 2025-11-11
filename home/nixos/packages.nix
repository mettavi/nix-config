{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pdfarranger # python-gtk application to merge/split/rotate/crop/rearrange PDFs
    wasistlos # Unofficial WhatsApp desktop gtk application for linux
    zoom-us # video conferencing application
  ];
}
