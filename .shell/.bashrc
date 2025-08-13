
# Load bash completion if available
if [ -e /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -e /usr/local/etc/bash_completion ]; then
    source /usr/local/etc/bash_completion
fi

if compgen -G "${HOME}/.shell/common.d/*" > /dev/null; then
    for f in ${HOME}/.shell/common.d/*; do
        [ -r "$f" ] && [ -f "$f" ] && source "$f"
    done
fi
if compgen -G "${HOME}/.shell/bash.d/*" > /dev/null; then
    for f in ${HOME}/.shell/bash.d/*; do
        [ -r "$f" ] && [ -f "$f" ] && source "$f"
    done
fi

# Default OS X prompt
# PS1='\h:\W \u\$'

# Bash 4+
export PROMPT_DIRTRIM=2

export GIT_PS1_SHOWSTASHSTATE=true
# shows $ if there are any stashes
export GIT_PS1_SHOWDIRTYSTATE=true
# shows % if there are any untracked files
export GIT_PS1_SHOWUNTRACKEDFILES=true
if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    # WSL
    export PS1='╭─\e[32m\u\e[90m@\e[1;34mWSL\e[0m\e[90m:\e[33m\W\e[35m $(__git_ps1 "%s")\n\e[0m╰ \$ '
else 
    export PS1='╭─\e[32m\u\e[90m@\e[1;34m\h\e[0m\e[90m:\e[33m\w\e[35m $(__git_ps1 "%s")\n\e[0m╰ \$ '

fi
