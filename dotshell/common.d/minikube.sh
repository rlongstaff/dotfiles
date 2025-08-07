
which minikube >& /dev/null
if [ $? = 0 ]; then
    source <(minikube docker-env)
fi
