# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


### ---- keybind config -------------------------------------

# use emacs mode despite setting EDITOR to vim
bindkey -e

# emulate ctrl-u in bash (ALT-k)
bindkey "^[k" backward-kill-line

# enable zsh widget to send command line to text editor
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^x^e" edit-command-line

# disable official git completion in favour of zsh git completion
# see https://bit.ly/3QXliO8 for details
\rm -f $HOMEBREW_PREFIX/share/zsh/site-functions/_git

# source aliases and functions
[[ -f $ZDOTDIR/.zsh_aliases ]] && source $ZDOTDIR/.zsh_aliases
[[ -f $ZDOTDIR/.zsh_functions ]] && source $ZDOTDIR/.zsh_functions

### ---- history config -------------------------------------

export HISTFILE=$ZDOTDIR/.zsh_history

# How many commands zsh will load to memory.
export HISTSIZE=10000

# How many commands history will save on file.
export SAVEHIST=10000

# Remove command from history if prepended with a space
setopt HIST_IGNORE_SPACE

# History won't save duplicates.
setopt HIST_IGNORE_ALL_DUPS

# History won't show duplicates on search.
setopt HIST_FIND_NO_DUPS

# Read and write $HISTFILE for each command
setopt SHARE_HISTORY

# load rbenv for managing ruby versions
eval "$(rbenv init - zsh)"

# Update fpath, enable and initialise zsh completions
fpath+=$ZDOTDIR/.zfunc
autoload -Uz compinit && compinit

# Load zsh plugins
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# enable antidote plugin manager
source /usr/local/opt/antidote/share/antidote/antidote.zsh
antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt

# source fzf and set its defaults
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# set up fzf defaults
export FZF_DEFAULT_OPTS="-m --height 50% --layout=reverse --border --inline-info 
  --preview-window=:hidden
  --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
  --bind '?:toggle-preview' 
"
export FZF_DEFAULT_COMMAND='fd --hidden --follow --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_ALT_C_COMMAND='fd --type directory --hidden --follow --strip-cwd-prefix --exclude .git'

# Configure fzf ** completion
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --follow --exclude .git . "$1"
}
# --------custom PATH entries -------------------------

# Added by n-install (see http://git.io/n-install-repo).
export N_PREFIX="$HOME/Applications/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  

export PATH="/Users/timotheos/Qt/6.6.0/macos/bin:$PATH"

export PATH="/usr/local/sbin:$PATH"

export PATH="/usr/local/opt/mongodb-community@5.0/bin:$PATH"
 
# Created by `pipx` on 2023-10-06 14:39:03
export PATH="$PATH:/Users/timotheos/.local/bin"
export PATH="/usr/local/opt/libarchive/bin:$PATH"

export PATH="$HOME/Applications/n/bin:$PATH"
# ---------------------------------------------------------
