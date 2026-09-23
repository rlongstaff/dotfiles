# tmux autostart, for both shells.
#
# Defined here, called as the last line of .bashrc / .zshrc, so the shell tmux returns to
# (detach, last window closed, tmux failed) is already fully loaded.  tmux runs as a child,
# never exec'd: a broken .tmux.conf or a client/server version mismatch after an upgrade
# still leaves a working shell.
#
# Sessions: the first terminal creates "main".  Every later terminal creates a session
# grouped with it: the same windows, but its own current window, so no terminal kicks
# another off.  Grouped sessions set destroy-unattached, so closing that terminal removes
# its session and they never pile up.  "main" itself persists until its last window closes.
#
# ssh: nested tmux.  This same function runs again on the remote host (dotfiles are assumed
# installed everywhere), so an ssh session gets its own "main" one level in -- independent
# of the local session, detachable on either end.  $TMUX is never forwarded by ssh, so
# nothing above stops that by itself; alt+x (keys.yaml) is the passthrough toggle so the
# outer session's keys can reach the nested one.  Two guards below specifically stop ssh'ing
# back into the same host from nesting a session inside itself ("tmux inception").
#
# Opt out for one terminal: DOTFILES_TMUX_AUTOSTART=0 kitty

dotfiles_tmux_autostart() {
  [ "${DOTFILES_TMUX_AUTOSTART:-1}" = 0 ] && return 0

  # Already inside tmux, or already autostarted from this shell (re-sourced rc, or
  # `exec zsh` after a detach).
  [ -n "$TMUX" ] && return 0
  [ -n "$DOTFILES_TMUX_STARTED" ] && return 0

  # Only a shell a person is typing into: interactive, not `-c` (`bash -lic exit` and
  # `zsh -lic exit` are the repo's own checks), attached to a terminal.
  case $- in
    *i*) ;;
    *) return 0 ;;
  esac
  # (Not zsh's shinstdin option: it is only set after the rc files have run.)
  [ -n "${BASH_EXECUTION_STRING}${ZSH_EXECUTION_STRING}" ] && return 0
  [ -t 0 ] && [ -t 1 ] || return 0

  which tmux >/dev/null 2>&1 || return 0
  case "$TERM" in
    ''|dumb) return 0 ;;
  esac

  # Terminals embedded in an editor or IDE.
  [ -n "${VIM}${INSIDE_EMACS}${EMACS}${ZED_TERM}" ] && return 0
  [ "$TERM_PROGRAM" = vscode ] && return 0
  [ "$TERMINAL_EMULATOR" = JetBrains-JediTerm ] && return 0

  # root: sudo -i / su - drop $TMUX, so this would nest a root tmux inside ours.
  [ "${EUID:-$(id -u)}" = 0 ] && return 0

  # Self-loop guard, layer 1: a direct ssh connection back to this same host (typically
  # by accident, e.g. a LAN/public IP that happens to route back here) is loopback-routed,
  # so sshd sees the client and server IPs coincide, or the client IP outright loopback.
  # Catching it here matters because $TMUX being unset (ssh never forwards it, see above)
  # is exactly what would otherwise let this function open a second client onto the very
  # session the outer pane already belongs to -- the session rendering inside itself.
  if [ -n "${SSH_CONNECTION}" ]; then
    set -- ${SSH_CONNECTION}
    case "$1" in
      127.*|::1) return 0 ;;
    esac
    [ "$1" = "$3" ] && return 0
  fi

  # Self-loop guard, layer 2: a longer chain that loops back through a DIFFERENT
  # intermediate host (laptop -> server01 -> laptop) never touches loopback, so layer 1
  # can't see it.  LC_DOTFILES_TMUX_CHAIN tracks host ids already visited; piggybacking on
  # the LC_* name means the near-universal "SendEnv LANG LC_*" / "AcceptEnv LANG LC_*"
  # default (Debian/Ubuntu OpenSSH, commonly elsewhere too) forwards it across a hop with
  # no wrapper script and no sshd_config edit on hosts we don't control.  Best-effort: if
  # that default isn't present on a given hop, this layer just doesn't see the chain there
  # and only layer 1 (direct loops) still applies.
  if [ -n "${SSH_CONNECTION}" ]; then
    _dt_host_id=$(hostname -f 2>/dev/null || hostname)
    case ":${LC_DOTFILES_TMUX_CHAIN:-}:" in
      *":${_dt_host_id}:"*) unset _dt_host_id; return 0 ;;
    esac
    export LC_DOTFILES_TMUX_CHAIN="${LC_DOTFILES_TMUX_CHAIN:+${LC_DOTFILES_TMUX_CHAIN}:}${_dt_host_id}"
    unset _dt_host_id
  fi

  export DOTFILES_TMUX_STARTED=1
  # `command`: an old oh-my-zsh `alias tmux=...` may still be alive in this shell.
  if command tmux has-session -t '=main' 2>/dev/null; then
    command tmux new-session -t '=main' \; set-option destroy-unattached on
  else
    # Two terminals opened at once can both see no "main": the loser joins the winner.
    command tmux new-session -s main \
      || { command tmux has-session -t '=main' 2>/dev/null \
           && command tmux new-session -t '=main' \; set-option destroy-unattached on; }
  fi
  _dt_rc=$?
  [ "$_dt_rc" = 0 ] || echo "tmux autostart: tmux exited with status ${_dt_rc}; plain shell" >&2
  unset _dt_rc
}
