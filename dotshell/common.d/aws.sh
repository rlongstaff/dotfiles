#!/bin/sh

which eksctl >& /dev/null
if [ $? == 0 ]; then
    source <(eksctl completion bash)
fi
