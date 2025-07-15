#!/usr/bin/env bash

# code borrowed from https://rgoswami.me/posts/managing-cloud-based-calibre/#3rd-use-rclone-manually

# Start calibre and wait
calibre
wait $! # optional really, but a bit safer

# Setup and run sync
# The --fast-list flag must be combined with the --onedrive-delta flag (or delta = true in the config file)
# as otherwise it can cause performance degradation
rclone --log-level INFO --log-file="$HOME/Library/Logs/rclone.log" \
  --stats 2s --progress --retries 1 --max-backlog 999999 --fast-list \
  sync ~/Documents/calibre/ --filter-from "$NIXFILES/home/shared/conf/rclone/filter-calibre.txt" onedrive:calibre/
