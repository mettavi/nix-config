#!/usr/bin/env bash

# code borrowed from https://rgoswami.me/posts/managing-cloud-based-calibre/#3rd-use-rclone-manually

# Start calibre and wait
calibre
wait $! # optional really, but a bit safer

# Setup and run sync
rclone --log-level NOTICE --log-file="${XDG_CONFIG_HOME}/rclone/log.txt" \
  --stats 2s --progress --check-first --retries 1 --max-backlog 999999 --buffer-size 256M \
  sync ~/Documents/calibre/ --filter-from ~/.config/rclone/filter.txt onedrive:calibre/
