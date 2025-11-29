{ pkgs, ... }:
{
  home.packages = with pkgs; [
    deja-dup # simple backup tool
    pdfarranger # python-gtk application to merge/split/rotate/crop/rearrange PDFs
    wasistlos # Unofficial WhatsApp desktop gtk application for linux
    zoom-us # video conferencing application
  ];
}
