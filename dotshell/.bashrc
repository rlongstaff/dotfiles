
if [ -e /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -e /usr/local/etc/bash_completion ]; then
    source /usr/local/etc/bash_completion
fi

I=$(dirname $0)
source ${I}/dotshell/common.d/*
source ${I}/dotshell/bash.d/*

# Default OS X prompt
# PS1='\h:\W \u\$'
if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    # WSL
    export PS1='[\u@WSL \W$(__git_ps1 " (%s)")]\$ '
else 
    export PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
fi
