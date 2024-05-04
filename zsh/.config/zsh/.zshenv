# Put $PATH variables in .zshrc, not here!
# See https://0xmachos.com/2021-05-13-zsh-path-macos/ for details
export JAVA_HOME=$(/usr/libexec/java_home) 
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"

export dotfiles="$HOME/.dotfiles"

# VISUAL is default for modern editors, EDITOR is historical fallback
export VISUAL="nvim"
export EDITOR="nvim"

# enable colorful ls output by default
export CLICOLOR=1

# open man pages from terminal with neovim
export MANPAGER="nvim +Man!"

export BAT_THEME=tokyonight_night
