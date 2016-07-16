source ~/.bash/git-completion.bash
source ~/.bash/git-prompt.sh
DOCKER_ENV=`docker-machine env 2>/dev/null`
if [ $? == 0 ]; then
    eval $DOCKER_ENV
fi

export PATH=$PATH:$HOME/bin:$HOME/Library/Android/sdk/platform-tools/

# Default OS X
# PS1='\h:\W \u\$'
PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '

alias vi=vim
