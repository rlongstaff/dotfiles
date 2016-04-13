source ~/.bash/git-completion.bash
source ~/.bash/git-prompt.sh
eval $(docker-machine env)

export PATH=$PATH:$HOME/bin:$HOME/Library/Android/sdk/platform-tools/

# Default OS X
# PS1='\h:\W \u\$'
PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
