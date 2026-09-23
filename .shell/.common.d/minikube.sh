
if command -v minikube >/dev/null 2>&1; then
    # process substitution: bash/zsh only, not dash, unlike the rest of .common.d
    source <(minikube docker-env)
fi
