# One ssh-agent per host, shared by every shell, tmux pane and ssh login, with keys loaded.
#
# SSH_AUTH_SOCK is always ~/.ssh/agent.<host>.sock, a symlink to whichever agent is live, so
# shells that are already open follow it when the agent changes. The target is, in order:
# the socket this shell inherited, the macOS launchd (Keychain) agent, the socket the systemd
# user session advertises (e.g. GNOME gcr), a known systemd socket, or an agent we start.
# An ssh login with a working forwarded agent keeps that agent and leaves the link alone.
#
# `ssh-add -l` exit codes: 0 keys loaded, 1 agent up but empty, 2 no agent.

# rc of the agent at $1: 0, 1 or 2 as above.
_ssh_agent_rc() {
  [ -n "$1" ] && [ -S "$1" ] || return 2
  SSH_AUTH_SOCK="$1" ssh-add -l >/dev/null 2>&1
}

# Adopt $1 if an agent answers there: sets _ssh_agent_found.
_ssh_agent_try() {
  [ -n "$1" ] && [ "$1" != "$_ssh_agent_link" ] || return 1
  _ssh_agent_rc "$1"
  [ $? -ne 2 ] || return 1
  _ssh_agent_found="$1"
}

# Empty agent: load keys, but only where a person can answer the passphrase prompt.
_ssh_agent_keys() {
  case $- in *i*) ;; *) return 0 ;; esac
  [ -t 0 ] || return 0
  ssh_refresh_keys
}

_ssh_agent_init() {
  local host rc lock real xdg
  host=$(uname -n); host=${host%%.*}
  _ssh_agent_link="$HOME/.ssh/agent.$host.sock"
  real="$HOME/.ssh/agent.$host.real"
  lock="$HOME/.ssh/agent.$host.lock"
  _ssh_agent_found=

  # Forwarded agent: this session only.
  if [ -n "$SSH_CONNECTION" ] && _ssh_agent_try "$SSH_AUTH_SOCK" ; then
    return 0
  fi

  # Fast path: the link is live.
  _ssh_agent_rc "$_ssh_agent_link"
  rc=$?
  if [ $rc -ne 2 ] ; then
    export SSH_AUTH_SOCK="$_ssh_agent_link"
    [ $rc -eq 1 ] && _ssh_agent_keys
    return 0
  fi

  [ -d "$HOME/.ssh" ] || mkdir -m 700 "$HOME/.ssh" 2>/dev/null
  rm -f "$HOME/.ssh/agent.env"  # legacy tracking file

  # Slow path: adopt a managed agent.
  xdg=${XDG_RUNTIME_DIR:-/nonexistent}
  _ssh_agent_try "$SSH_AUTH_SOCK" \
    || { which launchctl >/dev/null 2>&1 \
         && { _ssh_agent_try "$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null)" \
              || _ssh_agent_try "$(sh -c 'for s in /private/tmp/com.apple.launchd.*/Listeners; do
                   [ -O "$s" ] && echo "$s" && break; done' 2>/dev/null)"; }; } \
    || { which systemctl >/dev/null 2>&1 \
         && _ssh_agent_try "$(systemctl --user show-environment 2>/dev/null \
              | sed -n 's/^SSH_AUTH_SOCK=//p')"; } \
    || _ssh_agent_try "$xdg/gcr/ssh" \
    || _ssh_agent_try "$xdg/openssh_agent" \
    || _ssh_agent_try "$xdg/ssh-agent.socket" \
    || _ssh_agent_try "$xdg/keyring/ssh"

  # None: start our own. The lock stops shells opened together from each starting one.
  if [ -z "$_ssh_agent_found" ] ; then
    if ! mkdir "$lock" 2>/dev/null ; then
      sleep 1
      _ssh_agent_rc "$_ssh_agent_link"
      if [ $? -ne 2 ] ; then
        export SSH_AUTH_SOCK="$_ssh_agent_link"
        return 0
      fi
      rmdir "$lock" 2>/dev/null   # stale lock from a killed shell
      mkdir "$lock" 2>/dev/null
    fi
    if ! _ssh_agent_try "$real" ; then
      rm -f "$real"
      ssh-agent -a "$real" >/dev/null 2>&1
      _ssh_agent_try "$real"
    fi
    rmdir "$lock" 2>/dev/null
  fi

  [ -n "$_ssh_agent_found" ] || return 1
  ln -sfn "$_ssh_agent_found" "$_ssh_agent_link"
  export SSH_AUTH_SOCK="$_ssh_agent_link"
  _ssh_agent_rc "$SSH_AUTH_SOCK"
  [ $? -eq 1 ] && _ssh_agent_keys
  return 0
}

ssh_refresh_keys() {
  local host keyfile apple=0
  local key_lifetime=28800  # 8 hours
  host=${HOST:-$(uname -n)}
  echo "Refreshing SSH keys on ${host%%.*}..."
  # Only Apple's ssh-add knows the Keychain flags; Homebrew's openssh rejects them.
  if [ "$(uname -s)" = "Darwin" ] && [ "$(which ssh-add)" = "/usr/bin/ssh-add" ] ; then
    apple=1
    ssh-add --apple-load-keychain -t "$key_lifetime" >/dev/null 2>&1
  fi
  if ! ssh-add -l >/dev/null 2>&1 ; then
    for keyfile in ~/.ssh/id_rsa ~/.ssh/id_ed25519 ~/.ssh/id_ecdsa; do
      [ -f "$keyfile" ] || continue
      if [ $apple -eq 1 ] ; then
        ssh-add --apple-use-keychain -t "$key_lifetime" "$keyfile" 2>/dev/null
      else
        ssh-add -t "$key_lifetime" "$keyfile" 2>/dev/null
      fi
    done
  fi
  ssh-add -l
}

if which ssh-add >/dev/null 2>&1 ; then
  _ssh_agent_init
fi
unset -f _ssh_agent_init _ssh_agent_try _ssh_agent_rc _ssh_agent_keys
unset _ssh_agent_found _ssh_agent_link
