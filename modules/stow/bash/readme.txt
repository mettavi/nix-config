NB: The .stowrc file is placed in the first directory to be parsed by the symlinks.sh script.
(Currently this one.)
Stow should thus create the .config directory rather than symlink it.
After this, stow will not attempt to symlink this directory.
