
if [ -n "$ZSH_VERSION" ]; then
    GCLOUD_INC=(
        ${HOME}/prj/google-cloud-sdk/path.zsh.inc
        ${HOME}/prj/google-cloud-sdk/completion.zsh.inc
    )
elif [ -n "$BASH_VERSION" ]; then
    GCLOUD_INC=(
        ${HOME}/prj/google-cloud-sdk/path.bash.inc
        ${HOME}/prj/google-cloud-sdk/completion.bash.inc
    )
fi

for i in ${GCLOUD_INC[@]}; do
    if [ -f ${i} ]; then
        source ${i}
    fi
done
