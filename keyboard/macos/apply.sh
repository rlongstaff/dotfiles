#!/bin/sh
#
# Apply the keyboard standard on macOS.  See ../README.md for the standard itself.
#
#   Caps Lock      -> Control
#   left of space  -> Command      (already correct; nothing to do)
#   two left       -> Option       (already correct; nothing to do)
#
# So the only modifier change macOS needs is Caps -> Control.  That is one hidutil
# property, plus a LaunchAgent because hidutil does not survive a reboot or a keyboard
# being unplugged and replugged.
#
# Applies to every attached keyboard, which is the point: the internal keyboard, the
# Apple Aluminum full size and the compact Bluetooth keyboard all behave the same.
#
# Idempotent.  No-op off macOS.

set -e

[ "$(uname -s)" = "Darwin" ] || { echo "keyboard: not macOS; nothing applied"; exit 0; }

# Usage page 0x7 (keyboard), Caps Lock 0x39 -> Left Control 0xE0.
CAPS_TO_CTRL='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'

AGENT_DIR="${HOME}/Library/LaunchAgents"
AGENT_LABEL="us.longstaffkeyboard"
AGENT_PLIST="${AGENT_DIR}/${AGENT_LABEL}.plist"

hidutil property --set "${CAPS_TO_CTRL}" >/dev/null
echo "keyboard: Caps Lock -> Control applied to all attached keyboards"

mkdir -p "${AGENT_DIR}"
cat > "${AGENT_PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${AGENT_LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/hidutil</string>
    <string>property</string>
    <string>--set</string>
    <string>${CAPS_TO_CTRL}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

# bootout is expected to fail the first time, when nothing is loaded yet.
launchctl bootout "gui/$(id -u)/${AGENT_LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "${AGENT_PLIST}"
echo "keyboard: LaunchAgent ${AGENT_LABEL} installed; survives reboot"

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
