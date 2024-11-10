#### POWERLEVEL 10K ####
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


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

# How many commands zsh will load to memory.
# export HISTSIZE=100000

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


# Load zsh plugins
# source /nix/store/f5dmn5rkcwghvb1v4g062j38js5h3qwr-zsh-syntax-highlighting-0.8.0/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# source /nix/store/31c64327figpjpxhb3r3liwd872hf64n-zsh-abbr-5.6.0/share/zsh/zsh-abbr/abbr.plugin.zsh

# source additional zsh configurations
[[ -f $ZDOTDIR/.zsh_aliases ]] && source $ZDOTDIR/.zsh_aliases
[[ -f $ZDOTDIR/.zsh_completions ]] && source $ZDOTDIR/.zsh_completions # this must be loaded before fzf-tab (via antidote)

# load pyenv for managing python versions
eval "$(pyenv init -)"

# load rbenv for managing ruby versions
eval "$(rbenv init - zsh)"

# load zoxide and set its alias
# eval "$(zoxide init --cmd cd zsh )"

# enable and set custom alias
eval $(thefuck --alias oh)

# source the script for loading and configuring fzf
source ~/.config/fzf/.fzfrc

# source the script for loading and configuring atuin
source ~/.config/atuin/.atuinrc

# enable antidote plugin manager
# NB: source the fzf-tab antidote plugin after fzf to avoid problems with ** tab-completion
# source /nix/store/k3ia5k7s2zzqz39660cbz289c3yn850h-antidote-1.9.6/share/antidote/antidote.zsh
# NB: load directly from $DOTFILES as antidote overwrites symlinks
# antidote load ${DOTFILES}/zsh/.config/zsh/.zsh_plugins.txt

# Set up wrapper for brew-file package
# if [ -f $(brew --prefix)/etc/brew-wrap ];then
#   source $(brew --prefix)/etc/brew-wrap
#
#   _post_brewfile_update () {
#     echo "Brewfile was updated!"
#   }
# fi
 
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
