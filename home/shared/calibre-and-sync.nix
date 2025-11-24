{ pkgs, ... }:
with pkgs.stdenv;
let
  logfile_os =
    if isDarwin then "$HOME/Library/Logs/rclone.log" else "$XDG_STATE_HOME/logs/rsync/onedrive";
in
{
  home.packages =
    let
      calibre-and-sync =
        pkgs.writeShellScriptBin "calibre-and-sync.sh" # bash
          ''
            # code borrowed from https://rgoswami.me/posts/managing-cloud-based-calibre/#3rd-use-rclone-manually

            # Start calibre and wait
            calibre
            wait $! # optional really, but a bit safer

            # Setup and run sync
            # The --fast-list flag must be combined with the --onedrive-delta flag (or delta = true in the config file)
            # as otherwise it can cause performance degradation
            rclone --log-level INFO --log-file=${logfile_os} \
              --stats 2s --progress --retries 1 --max-backlog 999999 --fast-list \
              sync ~/Documents/calibre/ --filter-from "$NIXFILES/home/shared/conf/rclone/filter-calibre.txt" onedrive:calibre/ 
          '';
    in
    [ calibre-and-sync ];
}
