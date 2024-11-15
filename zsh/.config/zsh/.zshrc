#### keybind config ####

# use emacs mode despite setting EDITOR to vim
bindkey -e

# define duplicate binding (ctrl-alt-k) for kill-line (ctrl-k) for use in tmux
# which overwrites the default for navigating to pane above
bindkey "^[^k" kill-line
# emulate ctrl-u in bash (ALT-k) with alt-k
bindkey "^[k" backward-kill-line

# only match lines from command history with characters already typed
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# enable zsh widget to send command line to text editor
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^x^e" edit-command-line

#### history config #### 

# export HISTFILE=$ZDOTDIR/.zsh_history

# This option is now set by nix
# How many commands zsh will load to memory.
# export HISTSIZE=100000

# This option is now set by nix
# How many commands history will save on file.
# export SAVEHIST=100000

# Remove command from history if prepended with a space
setopt HIST_IGNORE_SPACE

setopt HIST_IGNORE_ALL_DUPS  # Delete old event if new is dup
setopt HIST_FIND_NO_DUPS  # Do not display previously found event

# Read and write $HISTFILE for each command 
# (implies INC_APPEND_HISTORY and incompatible with EXTENDED_HISTORY)
setopt SHARE_HISTORY


#################### LOAD PLUGINS & CONFIGS #################### 

# source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Load zsh plugins
if [[ -f "$HOME/.config/zsh/plugins/zsh-abbr/share/zsh/zsh-abbr/zsh-abbr.plugin.zsh" ]]; then
 source "$HOME/.config/zsh/plugins/zsh-abbr/share/zsh/zsh-abbr/zsh-abbr.plugin.zsh"
fi

# source additional zsh configurations
[[ -f $ZDOTDIR/.zsh_aliases ]] && source $ZDOTDIR/.zsh_aliases
[[ -f $ZDOTDIR/.zsh_completions ]] && source $ZDOTDIR/.zsh_completions # this must be loaded before fzf-tab (via antidote)

# load pyenv for managing python versions
eval "$(pyenv init -)"

# load rbenv for managing ruby versions
eval "$(rbenv init - zsh)"

# source the script for loading and configuring fzf
source ~/.config/fzf/.fzfrc

# source the script for loading and configuring atuin
source ~/.config/atuin/.atuinrc

# make sure these custom functions are sourced last
[[ -f $ZDOTDIR/.zsh_functions ]] && source $ZDOTDIR/.zsh_functions

# -------- custom PATH entries --------------------------------------

# Pyenv Python version manager
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Added by n-install (see http://git.io/n-install-repo).
export N_PREFIX="$HOME/util/n"; export PATH=$N_PREFIX/bin:$PATH

export PATH="/usr/local/sbin:$PATH"

export PATH="/usr/local/opt/mongodb-community@5.0/bin:$PATH"

# Created by `pipx` on 2023-10-06 14:39:03
export PATH="$PATH:/Users/timotheos/.local/bin"
export PATH="/usr/local/opt/libarchive/bin:$PATH"

# TODO: Delete this once https://github.com/microsoft/vscode/issues/204085 is fixed
# export PATH="$HOME/.local/bin:$PATH"

#################### CUSTOM ENVIRONMENT VARIABLES ######################
#
# Must be loaded after zsh-abbr/zsh-autosuggestions/zsh-autosuggestions-abbr-strategy
ZSH_AUTOSUGGEST_STRATEGY=( abbreviations $ZSH_AUTOSUGGEST_STRATEGY )
