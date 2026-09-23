#!/bin/sh

if command -v kubectl >/dev/null 2>&1; then
    export PATH="${HOME}/.krew/bin:${PATH}"
    export KUBECONFIG="${HOME}/.kube/config"

    # Completion for kubectl and kn: completion.sh
    alias kn=kubectl
fi
