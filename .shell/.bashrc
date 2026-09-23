
source ${HOME}/.shell/.dotfilesrc

# Load bash completion if available
if [ -e /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
else
    # Avoid elif for bash 3.x compatibility
    if [ -e /usr/local/etc/bash_completion ]; then
        source /usr/local/etc/bash_completion
    fi
fi

shopt -s nullglob
for f in ${HOME}/.shell/.common.d/*.inc ${HOME}/.shell/.common.d/*.sh; do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done
for f in ${HOME}/.shell/.bash.d/*.inc ${HOME}/.shell/.bash.d/*.sh ${HOME}/.shell/.bash.d/*.bash; do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done
shopt -u nullglob

# Default OS X prompt
# PS1='\h:\W \u\$'

# Bash 4+
export PROMPT_DIRTRIM=2

export GIT_PS1_SHOWSTASHSTATE=true
# shows $ if there are any stashes
export GIT_PS1_SHOWDIRTYSTATE=true
# shows % if there are any untracked files
export GIT_PS1_SHOWUNTRACKEDFILES=true
# Colour escapes are wrapped in \[ \] so readline does not count them as printable width.
# Without the wrapping readline thinks the prompt is 4 columns wider than it is (the \e[0m
# after the newline), so Home, End and Ctrl-Left/Right land in visibly wrong columns and
# long lines redraw over the prompt.  zsh needs no equivalent: %F{}/%f are zero-width to it
# by definition, which is why only the bash half had the defect.
#
# The colours are DOTFILES_C_BASH_* from .common.d/colors.sh, GENERATED from colors.yaml
# and already \[ \] wrapped.  Double quotes splice them in now; \$( and \\\$ keep the git
# call and the $/# prompt character for prompt time.
if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    # WSL
    export PS1="╭─${DOTFILES_C_BASH_USER}\u${DOTFILES_C_BASH_AT}@${DOTFILES_C_BASH_HOST}WSL\[\e[0m\]${DOTFILES_C_BASH_COLON}:${DOTFILES_C_BASH_PATH}\W${DOTFILES_C_BASH_GIT} \$(__git_ps1 \"%s\")\n\[\e[0m\]╰ \\\$ "
else 
    export PS1="╭─${DOTFILES_C_BASH_USER}\u${DOTFILES_C_BASH_AT}@${DOTFILES_C_BASH_HOST}\h\[\e[0m\]${DOTFILES_C_BASH_COLON}:${DOTFILES_C_BASH_PATH}\w${DOTFILES_C_BASH_GIT} \$(__git_ps1 \"%s\")\n\[\e[0m\]╰ \\\$ "

fi

# After the loader, so PATH is complete (.common.d/completion.sh).
dotfiles_completion

# Last: the shell tmux returns to is fully loaded (.common.d/tmux.sh).
dotfiles_tmux_autostart
