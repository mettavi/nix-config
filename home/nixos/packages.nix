{ inputs, pkgs, ... }:
let
  nixpkgs-unstable = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = with pkgs; [
    deja-dup # simple backup tool based on restic (special backup format)
    mpv # General-purpose media player, fork of MPlayer and mplayer2
    pdfarranger # python-gtk application to merge/split/rotate/crop/rearrange PDFs
    picard # offical musicbrainz tagger
    # install from nixpkgs-unstable until pr #484174 is lands in nixos-unstable
    # TODO: Revert when https://nixpk.gs/pr-tracker.html?pr=484174 shows the PR has landed in nixos-unstable
    nixpkgs-unstable.pika-backup # Simple backups based on borg (raw files backup format)
    wasistlos # Unofficial WhatsApp desktop gtk application for linux
    zoom-us # video conferencing application
  ];
}
