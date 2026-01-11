{ pkgs, ... }:
{
  home.packages = with pkgs; [
    deja-dup # simple backup tool based on restic (special backup format)
    mpv # General-purpose media player, fork of MPlayer and mplayer2
    pdfarranger # python-gtk application to merge/split/rotate/crop/rearrange PDFs
    wasistlos # Unofficial WhatsApp desktop gtk application for linux
    zoom-us # video conferencing application
  ];
}
