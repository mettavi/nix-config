#!/usr/bin/env bash

# code borrowed from https://rgoswami.me/posts/managing-cloud-based-calibre/#3rd-use-rclone-manually

# Start calibre and wait
calibre
wait $! # optional really, but a bit safer

# Setup and run sync
# The --fast-list flag must be used with the --onedrive-delta flag (or delta = true in the config file)
# as it can cause performance degradation
rclone --log-level NOTICE --log-file="${XDG_CONFIG_HOME}/rclone/log.txt" \
  --stats 2s --progress --check-first --retries 1 --max-backlog 999999 --buffer-size 256M --fast-list \
  sync ~/Documents/calibre/ --filter-from ~/.config/rclone/filter.txt onedrive:calibre/
