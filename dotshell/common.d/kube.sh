#!/bin/sh

which kubectl >& /dev/null
if [ $? = 0 ]; then
    export PATH="$HOME/.krew/bin:$PATH"
    export KUBECONFIG=$HOME/.kube/config

    # Detect shell and source kubectl completion accordingly
    if [ -n "$ZSH_VERSION" ]; then
        # Zsh
        source <(kubectl completion zsh)
    elif [ -n "$BASH_VERSION" ]; then
        # Bash
        source <(kubectl completion bash)
    fi

    if [ -n "$BASH_VERSION" ]; then
        if [[ $(type -t compopt) = "builtin" ]]; then
            complete -o default -F __start_kubectl kn
        else
            complete -o default -o nospace -F __start_kubectl kn
        fi
    fi

    alias kn=kubectl
fi
