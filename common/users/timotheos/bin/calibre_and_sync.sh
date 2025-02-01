#!/usr/bin/env bash

# code borrowed from https://rgoswami.me/posts/managing-cloud-based-calibre/#3rd-use-rclone-manually

# Start calibre and wait
calibre
wait $! # optional really, but a bit safer

# backup calibre library to the rclone onedrive backend using restic
restic -r rclone:onedrive:calibre backup "${HOME}/Documents/calibre"
