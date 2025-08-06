
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

if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    # WSL
    export PS1='[\u@WSL \W$(__git_ps1 " (%s)")]\$ '
else 
    export PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
fi
