#!/bin/sh
#
# Terminal-emulator half of the keyboard standard on Linux.  See ../README.md.
#
# The terminal emulator owns Cmd/Super, because Cmd/Super has no byte encoding and so
# can never reach tmux or vim.  iTerm2 already binds Cmd-C/V/T/W and Cmd-1..9 natively,
# so macOS needs nothing here -- this file exists to move Linux terminals onto Super so
# the two match.
#
# Copy and paste are tier-1: ONE gesture, single modifier plus key, identical on
# GNOME/Wayland, fluxbox/X11 and macOS, all writing the same CLIPBOARD selection.
# Terminals covered, in scope order: gnome-terminal and iTerm2 (required), alacritty and
# kitty (nice to have), xterm (optional, and the fluxbox/X11 guarantee).
#
# Firefox and other GTK/desktop applications are deliberately untouched -- they keep
# Ctrl-C/V.  Nothing here rebinds a global modifier; Super is *added* in the terminals,
# not substituted for Control anywhere.
#
#   Super-C / Super-V   copy / paste
#   Super-T / Super-W   new tab / close tab
#   Super-N             new window
#   Super-1 .. Super-9  tab N
#   Super-Left/Right    prev / next tab
#   Super-Tab           switch application  (the OS, not the terminal -- matches Cmd-Tab)
#
# Alt is left completely alone here: it belongs to tmux and vim.
#
# Idempotent.  Self-guarding: each block no-ops when its terminal is not installed.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
MODULE=keyboard
. "${SCRIPT_DIR}/scripts/lib.sh"

# Files this script reads.  Both are LINKS entries, so they resolve into the repo.
XRES="${TARGET}/.Xresources"
FLUXBOX_KEYS="${TARGET}/.fluxbox/keys"

# gsettings is per-session, not per-file: only the real home gets it.  The file-backed
# terminals (alacritty, kitty, xterm) are written under TARGET regardless.
if live_home && which gsettings >/dev/null 2>&1; then
  HAVE_GSETTINGS=1
else
  HAVE_GSETTINGS=""
fi

# --------------------------------------------------------------------------------------
# GNOME Shell first: it holds Super-1..9 for the dash, which would swallow the tab keys.
# --------------------------------------------------------------------------------------
if [ -n "${HAVE_GSETTINGS}" ] \
   && gsettings list-schemas 2>/dev/null | grep -q '^org\.gnome\.shell\.keybindings$'; then
  i=1
  while [ $i -le 9 ]; do
    gsettings set org.gnome.shell.keybindings "switch-to-application-${i}" "[]"
    i=$((i + 1))
  done

  # GNOME Shell also holds Super-A (the app grid) and Super-N (focus the last
  # notification).  Both are grabbed by the compositor, so they never reach the focused
  # terminal at all -- select-all and new-window would look bound and do nothing.
  gsettings set org.gnome.shell.keybindings toggle-application-view "[]"
  gsettings set org.gnome.shell.keybindings focus-active-notification "[]"

  # Super-V has shipped as toggle-message-tray in some GNOME versions.  It is the paste
  # key, so it is released unconditionally rather than checked: a grab here means paste
  # is dead in every terminal on the machine and nothing indicates why.
  gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>m']"

  log "released Super-1..9, Super-A, Super-N, Super-V from GNOME Shell"
fi

# --------------------------------------------------------------------------------------
# Alt-Tab belongs to the terminal, not the window manager.
#
# GNOME ships switch-applications bound to BOTH <Super>Tab and <Alt>Tab, so the same
# gesture is on two modifiers and the Alt one shadows tmux's pane cycling before the
# terminal ever sees the keystroke.  Pinning it to Super-Tab alone does two things at
# once: it matches macOS, where Cmd-Tab is the application switcher and Option-Tab is
# free, and it frees Alt-Tab to reach tmux -- which is the modifier rule this whole
# standard runs on (Super = OS and terminal emulator, Alt = inside the terminal).
#
# Same treatment for the backward pair, or Alt-Shift-Tab would still be caught here while
# Alt-Tab passed through, which is worse than either consistent outcome.
# --------------------------------------------------------------------------------------
if [ -n "${HAVE_GSETTINGS}" ] \
   && gsettings list-schemas 2>/dev/null | grep -q '^org\.gnome\.desktop\.wm\.keybindings$'; then
  gsettings set org.gnome.desktop.wm.keybindings switch-applications \
    "['<Super>Tab']"
  gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward \
    "['<Shift><Super>Tab']"
  log "Alt-Tab released to tmux; app switching is Super-Tab"
fi

# --------------------------------------------------------------------------------------
# gnome-terminal.  Relocatable schema, so the path suffix is mandatory.
# --------------------------------------------------------------------------------------
if [ -n "${HAVE_GSETTINGS}" ] && which gnome-terminal >/dev/null 2>&1; then
  GT="org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/"

  gsettings set "$GT" copy       "'<Super>c'"
  gsettings set "$GT" paste      "'<Super>v'"
  gsettings set "$GT" select-all "'<Super>a'"
  gsettings set "$GT" find       "'<Super>f'"
  gsettings set "$GT" new-tab    "'<Super>t'"
  gsettings set "$GT" close-tab  "'<Super>w'"
  gsettings set "$GT" new-window "'<Super>n'"
  gsettings set "$GT" prev-tab   "'<Super>Left'"
  gsettings set "$GT" next-tab   "'<Super>Right'"

  # switch-to-tab-N ships bound to <Alt>N, which would collide head-on with the tmux
  # window keys.  Moving them to Super is what frees Alt for tmux.
  i=1
  while [ $i -le 9 ]; do
    gsettings set "$GT" "switch-to-tab-${i}" "'<Super>${i}'"
    i=$((i + 1))
  done
  # Beyond 9 there is no Super key to use; unbind rather than leave them on Alt.
  i=10
  while [ $i -le 20 ]; do
    gsettings set "$GT" "switch-to-tab-${i}" "'disabled'" 2>/dev/null || true
    i=$((i + 1))
  done

  gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false
  log "gnome-terminal moved to Super; Alt released to tmux"
fi

# --------------------------------------------------------------------------------------
# alacritty and kitty read their config from files, and those files are repo files
# linked into TARGET by install.d/10-symlinks.sh (LINKS in scripts/lib.sh):
#
#   .config/alacritty/alacritty.toml
#   .config/kitty/kitty.conf
#
# Nothing to do here but say so; both terminals pick the file up on next start.
# --------------------------------------------------------------------------------------
for t in alacritty kitty; do
  have "$t" && log "$t reads the linked config; restart it to pick up changes"
done

# --------------------------------------------------------------------------------------
# xterm.  No config file of its own: shortcuts are X resources, and the modifier is
# spelled the Xt way ('Super', which is mod4 -- the same key GTK calls <Super>).  The
# resources are the repo's .Xresources, linked into TARGET; all this does is merge them
# into the running server so they take effect without a re-login.  This is the
# fluxbox/X11 path; xterm is the optional tier, but it is also the terminal a minimal X
# session is guaranteed to have.
# --------------------------------------------------------------------------------------
if have xterm && [ -f "${XRES}" ]; then
  if live_home && have xrdb && [ -n "${DISPLAY}" ]; then
    xrdb -merge "${XRES}" && log "xterm resources merged into the live server"
  else
    log "xterm resources take effect next X session (~/.Xresources)"
  fi
fi

# --------------------------------------------------------------------------------------
# fluxbox.  It grabs Mod4 combinations only if ~/.fluxbox/keys says so, which the stock
# file does not -- but a hand-edited one might, and a window-manager grab beats the
# terminal every time.  Warn rather than rewrite: keys(5) is the user's file.
# --------------------------------------------------------------------------------------
if [ -f "${FLUXBOX_KEYS}" ] \
   && grep -qiE '^[[:space:]]*mod4[[:space:]]+[cv][[:space:]]' "${FLUXBOX_KEYS}"; then
  log "WARNING ~/.fluxbox/keys grabs Mod4-C or Mod4-V; copy/paste will not"
  log "reach the terminal until those lines are removed."
fi

# No tab bindings for alacritty (it has no tabs) or xterm (it has none either); both are
# reachable through tmux, which is the point of putting the frequent operations there.
