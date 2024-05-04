#! /usr/bin/env bash

# Download the git script for fzf
git clone git@github.com:junegunn/fzf-git.sh.git ~/

# This has to be applied after brew has installed cask logi-options-plus
patch  /Library/Application\ Support/Logitech.localized/LogiOptionsPlus/app_permissions.json < ./app_permissions.json.diff

# Download theme after brew has installed bat
curl -O https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme --create-dirs --output $(bat --config-dir)/themes
