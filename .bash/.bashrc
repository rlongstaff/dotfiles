
BASH_INC=(
    ${HOME}/.bash/.bashrc.inc
    ${HOME}/.bash/git-completion.bash
    ${HOME}/.bash/git-prompt.sh
    ${HOME}/prj/google-cloud-sdk/path.bash.inc
    ${HOME}/prj/google-cloud-sdk/completion.bash.inc
    ${HOME}/prj/virtualenv/main/bin/activate
)

for i in ${BASH_INC[@]}; do
    if [ -f ${i} ]; then
        source ${i}
    fi
done

export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/src/go/bin:$PATH
export PATH=$HOME/.krew/bin:$PATH
export PATH=$HOME/.docker/bin:$PATH
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools/
export PATH=$PATH:/Applications/Development/Visual\ Studio\ Code.app/Contents/Resources/app/bin

export EDITOR=/usr/bin/vim

alias vi=vim
alias tf=tofu

which kubectl >& /dev/null
if [ $? == 0 ]; then
    export KUBECONFIG=$HOME/.kube/config
    source <(kubectl completion bash)
    alias kn=kubectl
    if [[ $(type -t compopt) = "builtin" ]]; then
        complete -o default -F __start_kubectl kn
    else
        complete -o default -o nospace -F __start_kubectl kn
    fi
fi

which eksctl >& /dev/null
if [ $? == 0 ]; then
    source <(eksctl completion bash)
fi

which minikube >& /dev/null
if [ $? == 0 ]; then
    source <(minikube docker-env)
fi

if [ -f ${HOME}/prj/virpy/main/bin/activate ]; then
    source ${HOME}/prj/virpy/main/bin/activate
fi

# Default OS X prompt
# PS1='\h:\W \u\$'
if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    # WSL
    export PS1='[\u@WSL \W$(__git_ps1 " (%s)")]\$ '
else 
    export PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
fi

AGENT_FILE="$HOME/.ssh/agent.env"
AGENT_CMD="/usr/bin/ssh-agent -s"

start_ssh_agent() {
       if [ -f $AGENT_FILE -a -z "$SSH_AGENT_PID" ]; then
               source $AGENT_FILE
       fi
       /bin/ps -p $SSH_AGENT_PID >& /dev/null
       if [ $? != 0 ]; then
               echo "Stale agent. Killing pidfile."
               $AGENT_CMD | grep -v echo > $AGENT_FILE 2>/dev/null
               source $AGENT_FILE
               /bin/chmod 600 $AGENT_FILE
       fi
}

start_ssh_agent
