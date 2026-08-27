#set -x
_ssh_agent_init() {
  local env_file="$HOME/.ssh/agent.env"
  local agent_socket_valid=0
  local key_lifetime=28800  # 8 hours

  # # Try to use cached agent first
  if [ -n "${SSH_AUTH_SOCK}" ] && [ -S "$SSH_AUTH_SOCK" ] ; then
    # We have an agent ENV and it is a socket
    # Do not let the env_file overwrite "valid" state
    : # Do nothing
  elif [ -f "$env_file" ] ; then
    . "$env_file"
  fi

  if ssh-add -l >/dev/null 2>&1 ; then
    agent_socket_valid=1
  fi

  # If cached agent is dead, start fresh
  if [ $agent_socket_valid -eq 0 ] ; then
    rm -f "$env_file"

    case "$(uname -s)" in
      Darwin)
        if ! pgrep -x ssh-agent >/dev/null 2>&1; then
          launchctl start com.openssh.ssh-agent 2>/dev/null
        fi
        ;;
      *)
        eval "$(ssh-agent -s)" >/dev/null
        ;;
    esac

    # Skip SSH_AGENT_PID
    cat > "$env_file" <<EOF
export SSH_AUTH_SOCK="$SSH_AUTH_SOCK"
EOF
    chmod 600 "$env_file"

    ssh_refresh_keys
  fi
}

ssh_refresh_keys() {
  local ssh_add_opts=''
  local key_lifetime=28800  # 8 hours
  echo "Refreshing SSH keys on ${HOST}..."
  for keyfile in ~/.ssh/id_rsa ~/.ssh/id_ed25519 ~/.ssh/id_ecdsa; do
    if [ -f "$keyfile" ]; then
      if [ "$(uname -s)" = "Darwin" ]; then
        ssh_add_opts="--apple-use-keychain"
      fi
      ssh-add ${ssh_add_opts} -t "$key_lifetime" "$keyfile" 2>/dev/null
    fi
  done
  ssh-add -l
}

_ssh_agent_init
unset _ssh_agent_init
#set +x
