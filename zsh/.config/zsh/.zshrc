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

# emulate ctrl-u in bash (ALT-k)
bindkey "^[k" backward-kill-line

# only match lines from command history with characters already typed
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# enable zsh widget to send command line to text editor
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^x^e" edit-command-line

####################  Config zsh completions ############################

# Update fpath, enable and initialise zsh extensions
if type brew &>/dev/null; then
  # Additional completion definitions for zsh
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  FPATH=$(brew --prefix)/share/zsh-abbr:$FPATH
fi
fpath+=$ZDOTDIR/.zfunc
autoload -Uz compinit && compinit
_comp_options+=(globdots)		# Include hidden files.

# Completion styling
# Show colours in preview when using tab-completion
# First check whether OS is Linux or macOS (GNU vs FreeBSD ls commands)
# and generate the $LS_COLORS variable
if whence dircolors >/dev/null; then  # Linux
  eval "$(dircolors -b)"
  alias ls='ls --color' # sets GNU ls default to show color
elif whence gdircolors >/dev/null; then  # macOS
  eval "$(gdircolors -b)"  # requires the coreutils package to be installed (eg homebrew)
  export CLICOLOR=1 # sets macOS ls default to show color
else
  echo "No (g)dircolors command found!"
fi
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Make completion case insensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# set descriptions format to enable group support
# NB: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# enable fzf-tab for zoxide in case its alias is no longer cd
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
# set different preview windows for files and directories
# limit this to commands which take file/folder arguments
cmd_preview=(gls trash rmdir mv cp file)
for cmd in ${cmd_preview[@]}
do
  zstyle ":fzf-tab:complete:$cmd:*" fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || eza -la --color=always $realpath'
done
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# disable official git completion in favour of zsh git completion
# see https://bit.ly/3QXliO8 for details
\rm -f $HOMEBREW_PREFIX/share/zsh/site-functions/_git

################################################################


#### history config #### 

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


#################### LOAD PLUGINS & CONFIGS #################### 


# Load zsh plugins
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/local/share/zsh-abbr/zsh-abbr.zsh # for expanding abbreviations in zsh

# source aliases and functions
[[ -f $ZDOTDIR/.zsh_aliases ]] && source $ZDOTDIR/.zsh_aliases
[[ -f $ZDOTDIR/.zsh_functions ]] && source $ZDOTDIR/.zsh_functions

# load pyenv for managing python versions
eval "$(pyenv init -)"

# load rbenv for managing ruby versions
eval "$(rbenv init - zsh)"

# ---- Zoxide (better cd) ----
eval "$(zoxide init --cmd cd zsh )"

# enable and set custom alias
eval $(thefuck --alias oh)

# source config for fzf
source ~/.config/fzf/.fzfrc

# enable antidote plugin manager
# NB: source the fzf-tab antidote plugin after fzf to avoid problems with ** tab-completion
source $(brew --prefix)/opt/antidote/share/antidote/antidote.zsh
# NB: load directly from $DOTFILES as the fzf-tab plugin does not work with symlinks
antidote load ${DOTFILES}/zsh/.config/zsh/.zsh_plugins.txt

# source script which runs 'brew which-formula' on unknown command
HB_CNF_HANDLER="$(brew --repository)/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
if [ -f "$HB_CNF_HANDLER" ]; then
source "$HB_CNF_HANDLER";
fi

# Set up wrapper for brew-file package
if [ -f $(brew --prefix)/etc/brew-wrap ];then
  source $(brew --prefix)/etc/brew-wrap

  _post_brewfile_update () {
    echo "Brewfile was updated!"
  }
fi
 

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

