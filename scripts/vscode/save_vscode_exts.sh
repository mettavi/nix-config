#! /usr/bin/env bash
code --list-extensions |
xargs -L 1 echo code --install-extension |
sed "s/$/ --force/" |
sed "\$!s/$/ \&/" > install_vscode_exts.sh
chmod +x ./install_vscode_exts.sh
