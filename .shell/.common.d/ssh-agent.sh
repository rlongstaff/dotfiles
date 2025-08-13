

AGENT_FILE="$HOME/.ssh/agent.env"
AGENT_CMD=(/usr/bin/ssh-agent -s)

start_ssh_agent() {
       if [ -f $AGENT_FILE -a -z "$SSH_AUTH_SOCK" ]; then
               source $AGENT_FILE
       fi
       if [ ! -e $SSH_AUTH_SOCK ]; then
               echo "Stale agent. Killing pidfile."
               "$AGENT_CMD[@]" | grep -v echo > $AGENT_FILE 2>/dev/null
               source $AGENT_FILE
               /bin/chmod 600 $AGENT_FILE
       fi
}

start_ssh_agent
