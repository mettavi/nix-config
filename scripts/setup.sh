#! /usr/bin/env bash

git clone git@github.com:junegunn/fzf-git.sh.git ~/

# This has to be applied after brew has installed cask logi-options-plus
patch  /Library/Application\ Support/Logitech.localized/LogiOptionsPlus/app_permissions.json < ./app_permissions.json.diff
