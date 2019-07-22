source ~/.bash/git-completion.bash
source ~/.bash/git-prompt.sh
eval $(kubectl completion bash)

export PATH=$PATH:$HOME/bin:$HOME/Library/Android/sdk/platform-tools/
export PATH=$PATH:/Applications/Development/Visual\ Studio\ Code.app/Contents/Resources/app/bin

alias vi=vim

. ~/prj/virpy/main/bin/activate

# Default OS X
# PS1='\h:\W \u\$'
PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
