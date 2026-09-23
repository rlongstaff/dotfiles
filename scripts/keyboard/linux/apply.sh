#!/bin/sh
#
# Apply the keyboard standard on Linux.  See docs/guide.md, "Keyboard standard", for the
# standard itself.
# Run by scripts/install.d/30-keyboard.sh, or by hand at any time.
#
#   Caps Lock      -> Control      (ctrl:nocaps)
#   left of space  -> Super        (altwin:swap_lalt_lwin)
#   two left       -> Alt          (same swap, other direction)
#
# This is the entry point for the Linux side: it applies the modifier remap, then runs
# terminal.sh for the emulator shortcuts.  The two are separate files because they act on
# different layers -- xkb rewrites keysyms for the whole session, terminal.sh rewrites
# accelerators inside each emulator -- but there is no case for running only one.
#
# Idempotent.  Self-guarding: silently does nothing on a machine that lacks the tool
# for its session type.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
MODULE=keyboard
. "${SCRIPT_DIR}/scripts/lib.sh"

KBD_DIR="${SCRIPT_DIR}/scripts/keyboard/linux"

# xkb, gsettings and xkbcomp all act on the live session, not on files under TARGET.
if ! live_home; then
  log "TARGET is not \$HOME; skipping the live-session modifier remap"
  exit 0
fi

XKB_LAYOUT="us"
XKB_OPTIONS="ctrl:nocaps,altwin:swap_lalt_lwin"

# Runs after the layout is applied; a machine file overrides it to bolt on anything
# stock xkb options cannot express.  Defined first so the override wins.
xkb_extra() { :; }

# Per-machine deviation, keyed on short hostname.  Sourced before anything is applied,
# so it may rewrite XKB_LAYOUT / XKB_OPTIONS or redefine xkb_extra().
HOST=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo unknown)
if [ -f "${KBD_DIR}/machines/${HOST}.sh" ]; then
  . "${KBD_DIR}/machines/${HOST}.sh"
fi

apply_gnome() {
  # Wayland ignores setxkbmap entirely; GNOME owns the xkb state via gsettings.
  gsettings set org.gnome.desktop.input-sources sources \
    "[('xkb', '${XKB_LAYOUT}')]"
  gsettings set org.gnome.desktop.input-sources xkb-options \
    "['$(echo "${XKB_OPTIONS}" | sed "s/,/', '/g")']"
  log "applied via gsettings (${XKB_OPTIONS})"
}

apply_x11() {
  setxkbmap -layout "${XKB_LAYOUT}" -option "" -option "${XKB_OPTIONS}"
  log "applied via setxkbmap (${XKB_OPTIONS})"
}

case "${XDG_SESSION_TYPE}" in
  wayland)
    if which gsettings >/dev/null 2>&1; then
      apply_gnome
    else
      log "wayland session with no gsettings; nothing applied" >&2
      exit 1
    fi
    ;;
  x11|"")
    # GNOME on X11 still reads gsettings, and it outlasts setxkbmap.  Do both when
    # GNOME is present so the setting survives a session restart.
    if [ "${XDG_CURRENT_DESKTOP#*GNOME}" != "${XDG_CURRENT_DESKTOP}" ] \
       && which gsettings >/dev/null 2>&1; then
      apply_gnome
    fi
    if which setxkbmap >/dev/null 2>&1; then
      apply_x11
    fi
    ;;
esac

xkb_extra

# Terminal-emulator half.  Runs last so the modifier remap is in place first: on GNOME the
# gsettings writes below are read against the layout applied above.
run_script "${KBD_DIR}/terminal.sh"
