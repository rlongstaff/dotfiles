#!/bin/sh

BASH_INC=(
    ${HOME}/prj/google-cloud-sdk/path.bash.inc
    ${HOME}/prj/google-cloud-sdk/completion.bash.inc
)

for i in ${BASH_INC[@]}; do
    if [ -f ${i} ]; then
        source ${i}
    fi
done

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Volumes/prj/google-cloud-sdk/path.zsh.inc' ]; then . '/Volumes/prj/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Volumes/prj/google-cloud-sdk/completion.zsh.inc' ]; then . '/Volumes/prj/google-cloud-sdk/completion.zsh.inc'; fi
