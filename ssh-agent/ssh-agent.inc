# source this in the profile.

AGENT_FILE="$HOME/tmp/agent.env"
AGENT_CMD="/usr/bin/ssh-agent -s"

start_ssh_agent() {
       if [ -f $AGENT_FILE -a "x" == "x$SSH_AGENT_PID" ]; then
               . $AGENT_FILE
       fi
       /bin/ps -p $SSH_AGENT_PID >& /dev/null
       if [ $? != 0 ]; then
               echo "Stale agent. Killing pidfile"
               $AGENT_CMD > $AGENT_FILE 2>/dev/null
               . $AGENT_FILE
               /bin/chmod 600 $AGENT_FILE
       fi
}
