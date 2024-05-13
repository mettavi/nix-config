# Change default location of bash history file to $XDG_CONFIG_HOME
export HISTFILE="$HOME/.config/bash/.bash_history"

# Source scripts from bash-completion brew package
if type brew &>/dev/null; then
	HOMEBREW_PREFIX="$(brew --prefix)"
	if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
		source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
	else
		for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
			[[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
		done
	fi
fi

# Source fzf script for bash
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
