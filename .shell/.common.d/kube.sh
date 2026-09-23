#!/bin/sh

which kubectl >& /dev/null
if [ $? = 0 ]; then
    export PATH="${HOME}/.krew/bin:${PATH}"
    export KUBECONFIG="${HOME}/.kube/config"

    # Completion for kubectl and kn: completion.sh
    alias kn=kubectl
fi
