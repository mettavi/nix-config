{ lib, pkgs, ... }:
with lib;
with pkgs.stdenv;
let
  logfile_os =
    if isDarwin then "$HOME/Library/Logs/rclone.log" else "$XDG_STATE_HOME/logs/rclone/onedrive.log";
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
{
  home.packages = [ calibre-and-sync ];

  xdg.desktopEntries.CaliSync = mkIf pkgs.stdenv.isLinux {
    name = "CaliSync";
    exec = "${calibre-and-sync}/bin/calibre-and-sync.sh";
    icon = "${pkgs.calibre}/share/icons/hicolor/128x128/apps/calibre-gui.png";
    terminal = true;
    categories = [
      "Office"
    ];
  };
}
