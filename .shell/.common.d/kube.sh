#!/bin/sh

which kubectl >& /dev/null
if [ $? = 0 ]; then
    export PATH="${HOME}/.krew/bin:${PATH}"
    export KUBECONFIG="${HOME}/.kube/config"

    alias kn=kubectl

    if [ -n "${BASH_VERSION}" ]; then
        # Bash 3.x does not support process substitution, so use a temp file
        _KUBE_COMPLETION_TMP="/tmp/kubectl_bash_completion.$$"
        kubectl completion bash > "$_KUBE_COMPLETION_TMP"
        source "$_KUBE_COMPLETION_TMP"
        rm -f "$_KUBE_COMPLETION_TMP"
        if [ "$(type -t compopt 2>/dev/null)" = "builtin" ]; then
            complete -o default -F __start_kubectl kn
        else
            complete -o default -o nospace -F __start_kubectl kn
        fi
    fi

    # Use this or OMZ?
    # if [ -n "${ZSH_VERSION}" ]; then
    #     source <(kubectl completion zsh)
    #     compdef __start_kubectl kn
    # fi
fi
