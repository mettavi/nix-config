# Put $PATH variables in .zshrc, not here!
# See https://0xmachos.com/2021-05-13-zsh-path-macos/ for details

#### XDG Directories (confirmation of defaults) ####

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_BIN_HOME="$HOME/.local/bin" # Not in the official XDG specification

#### Custom script variables  ####

export DEVFILES="$HOME/Developer"
export NIXFILES="$HOME/.nix-config"

##### Installed binaries - HOME DIRECTORIES #####

export PYENV_ROOT="$HOME/.pyenv"


##### Installed binaries - CONFIG ###### 

export BAT_THEME=tokyonight_night

export ABBR_USER_ABBREVIATIONS_FILE="$NIXFILES/modules/zsh/.config/zsh/user-abbreviations"

export NH_FLAKE="$NIXFILES"

########## SHELL CONFIG ###########

export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"

# VISUAL is default for modern editors, EDITOR is historical fallback
export VISUAL="nvim"
export EDITOR="nvim"

# open man pages from terminal with neovim
export MANPAGER="nvim +Man!"

# notify about new mail from postfix MTA (eg. for mail bounces from bitwarden backup script)
export MAIL="/var/mail/timotheos"
