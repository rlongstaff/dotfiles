#!/bin/sh
#
# Apply the keyboard standard on macOS.  See docs/guide.md, "Keyboard standard", for the
# standard itself.
# Run by scripts/install.d/30-keyboard.sh, or by hand at any time.
#
#   Caps Lock      -> Control
#   left of space  -> Command      (already correct; nothing to do)
#   two left       -> Option       (already correct; nothing to do)
#
# So the only modifier change macOS needs is Caps -> Control.  That is one hidutil
# property now, plus loading the LaunchAgent (Library/LaunchAgents/ in the repo) because
# hidutil does not survive a reboot or a keyboard being unplugged and replugged.
#
# Applies to every attached keyboard, which is the point: the internal keyboard, the
# Apple Aluminum full size and the compact Bluetooth keyboard all behave the same.
#
# Idempotent.  No-op off macOS.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
MODULE=keyboard
. "${SCRIPT_DIR}/scripts/lib.sh"

[ "$(uname -s)" = "Darwin" ] || { log "not macOS; nothing applied"; exit 0; }

# Usage page 0x7 (keyboard), Caps Lock 0x39 -> Left Control 0xE0.  The same literal is
# in the LaunchAgent plist below; keep them identical.
CAPS_TO_CTRL='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'

# Files this script reads.  The plist is a repo file, linked into TARGET by
# install.d/10-symlinks.sh (LINKS in scripts/lib.sh, darwin only).
AGENT_LABEL="us.longstaff.keyboard"
AGENT_PLIST="${TARGET}/Library/LaunchAgents/${AGENT_LABEL}.plist"

if ! live_home; then
  log "TARGET is not \$HOME; hidutil and launchctl skipped"
  exit 0
fi

hidutil property --set "${CAPS_TO_CTRL}" >/dev/null
log "Caps Lock -> Control applied to all attached keyboards"

if [ -f "${AGENT_PLIST}" ]; then
  # bootout is expected to fail the first time, when nothing is loaded yet.
  launchctl bootout "gui/$(id -u)/${AGENT_LABEL}" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "${AGENT_PLIST}"
  log "LaunchAgent ${AGENT_LABEL} loaded; survives reboot"
else
  warn "${AGENT_PLIST} not linked; run scripts/install.d/10-symlinks.sh"
fi

cat <<'EOF'

Two settings hidutil cannot reach.  Set them once, by hand:

  1. Touch Bar MacBook Pro
     Settings -> Keyboard -> Touch Bar shows: F1, F2, etc. Keys
     Settings -> Keyboard -> Press and hold fn key to: Show Control Strip
     Without this the machine has no Escape and no function row, and the vim
     debug keys (F5/F9/F10/F11) are unreachable.

  2. iTerm2 -- Option must reach tmux and vim as Meta
     Profiles -> Keys -> General -> Left Option key:  Esc+
                                    Right Option key: Esc+
EOF
