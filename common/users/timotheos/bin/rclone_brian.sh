#!/usr/bin/env bash
#
# This script will tar, compress, stream and copy a archive of Brian's home directory to AWS S3 Glacier Deep Archive using rclone
tar -zcvf - /Volumes/Brian/Users/ibrianallen --exclude-from="$NIXFILES/common/users/timotheos/conf/rclone/exclude-brian.txt" |
  rclone --dry-run --progress --stats 2s --verbose=2 --log-file="$HOME/Library/Logs/rclone-teststderr.log" --fast-list \
  rcat --dump filters --transfers 100 --checkers 200 aws_gda-crypt:/brian_macos_10.11.6.tar.gz | tee ~/Library/Logs/rclone-teststdout.log
