{
  nixosConfig,
  pkgs,
  ...
}:
let
  currentVersion = builtins.fromJSON nixosConfig.system.nixos.release;
in

{
  # TODO: Remove this after upgrading to nixos version 26.11
  # disable nushell integration on version 26.05 to prevent the assertion error for the fzf package
  # "fzf package version must be 0.73.0 or greater for nushell integration"
  home.shell.enableNushellIntegration = currentVersion > 26.05;

  home.packages = with pkgs; [
    kdePackages.okular # KDE document viewer
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
