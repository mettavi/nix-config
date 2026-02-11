{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with pkgs.stdenv;
let
  cfg = config.mettavi.system.apps.calibre;
  logfile_dir = if isDarwin then "$HOME/Library/Logs/rclone" else "$XDG_STATE_HOME/logs/rclone";
  logfile = "${logfile_dir}/onedrive.log";
  calibre-and-sync =
    pkgs.writeShellScriptBin "calibre-and-sync.sh" # bash
      ''
        # code borrowed from https://rgoswami.me/posts/managing-cloud-based-calibre/#3rd-use-rclone-manually

        # Start calibre and wait
        calibre
        wait $! # optional really, but a bit safer

        # Setup and run sync

        # create the base directory if it doesn't exist
        if [ ! -d ${logfile_dir} ]; then
          mkdir -p ${logfile_dir} 
        fi
        # The --fast-list flag must be combined with the --onedrive-delta flag (or delta = true in the config file)
        # as otherwise it can cause performance degradation
        rclone --log-level INFO --log-file=${logfile} \
          --stats 2s --progress --retries 1 --max-backlog 999999 --fast-list \
          sync ${cfg.cal_lib} --filter-from "$NIXFILES/home/shared/conf/rclone/filter-calibre.txt" onedrive:calibre/ 
      '';
in
{
  home-manager.users.${username} =
    { osConfig, ... }:
    lib.mkIf osConfig.mettavi.system.apps.calibre.enable {
      home.packages = with pkgs; [
        calibre-and-sync
        rclone # sync files and directories to and from major cloud storage
      ];

      /*
        To list all .desktop files, run:
        ls /run/current-system/sw/share/applications # for global packages
        ls /etc/profiles/per-user/$(id -n -u)/share/applications # for user packages
      */
      xdg.desktopEntries.CaliSync = mkIf pkgs.stdenv.isLinux {
        name = "CaliSync";
        exec = "${calibre-and-sync}/bin/calibre-and-sync.sh";
        icon = "${pkgs.calibre}/share/icons/hicolor/128x128/apps/calibre-gui.png";
        terminal = true;
        categories = [
          "Office"
        ];
      };
    };
}
