
which eksctl >& /dev/null
if [ $? = 0 ]; then
    if [ -n "$ZSH_VERSION" ]; then
        source <(eksctl completion zsh)
    elif [ -n "$BASH_VERSION" ]; then
        source <(eksctl completion bash)
    fi
fi
