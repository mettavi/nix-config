#!/usr/bin/env bash
#
# This script will tar, compress, stream and copy a archive of Brian's home directory to AWS S3 Glacier Deep Archive using rclone
tar -zcvf - /Volumes/Brian/Users/ibrianallen --exclude-from="$DOTFILES/common/users/timotheos/conf/rclone/exclude-brian.txt" |
  rclone --dry-run --progress --stats 2s -vv --log-file=~/Library/Logs/rclone.log --fast-list \
  rcat --transfers 100 --checkers 200 aws_gda-crypt:/brian_macos_10.11.6.tar.gz
