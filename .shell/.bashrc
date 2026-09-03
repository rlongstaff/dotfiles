
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
if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    # WSL
    export PS1='╭─\[\e[32m\]\u\[\e[90m\]@\[\e[1;34m\]WSL\[\e[0m\]\[\e[90m\]:\[\e[33m\]\W\[\e[35m\] $(__git_ps1 "%s")\n\[\e[0m\]╰ \$ '
else 
    export PS1='╭─\[\e[32m\]\u\[\e[90m\]@\[\e[1;34m\]\h\[\e[0m\]\[\e[90m\]:\[\e[33m\]\w\[\e[35m\] $(__git_ps1 "%s")\n\[\e[0m\]╰ \$ '

fi
