. /usr/local/etc/bash_completion

if [ -e ~/.bashrc ]; then
    source ~/.bashrc
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/rob/prj/google-cloud-sdk/path.bash.inc' ]; then .  '/Users/rob/prj/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/rob/prj/google-cloud-sdk/completion.bash.inc' ]; then .  '/Users/rob/prj/google-cloud-sdk/completion.bash.inc'; fi
eval $(minikube docker-env)

