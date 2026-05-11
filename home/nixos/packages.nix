{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    mpv # General-purpose media player, fork of MPlayer and mplayer2
    pdfarranger # python-gtk application to merge/split/rotate/crop/rearrange PDFs
    picard # offical musicbrainz tagger
    variety # wallpaper manager
    karere # Gtk4 WhatsApp client
    # wasistlos # no longer developed, replaced with karere 
    zoom-us # video conferencing application
  ];

  xdg.autostart = {
    enable = true;
    entries = [
      "${pkgs.variety}/share/applications/variety.desktop"
    ];
  };

}
