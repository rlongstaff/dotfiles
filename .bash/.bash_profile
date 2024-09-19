
if [ -e /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -e /usr/local/etc/bash_completion ]; then
    source /usr/local/etc/bash_completion
fi

if [ -e ~/.bashrc ]; then
    source ~/.bashrc
fi

if [ -e ~/.bash/.bashrc ]; then
    source ~/.bash/.bashrc
fi
