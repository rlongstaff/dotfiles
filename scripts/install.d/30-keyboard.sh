#!/bin/sh
#
# Keyboard standard (docs/keyboard.md): one script per platform, chosen here.
# Both are idempotent and self-guarding, and both act on the live session, so they are
# skipped for a throwaway TARGET and for a Linux session with no display.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
. "${SCRIPT_DIR}/scripts/lib.sh"

KBD="${SCRIPT_DIR}/scripts/keyboard"

case "$(uname -s)" in
  Darwin)
    run_script "${KBD}/macos/apply.sh"
    ;;
  Linux)
    if [ -z "${DISPLAY}" ] && [ -z "${WAYLAND_DISPLAY}" ]; then
      log "no display; run scripts/keyboard/linux/apply.sh from a desktop session"
      exit 0
    fi
    run_script "${KBD}/linux/apply.sh"
    ;;
  *)
    log "no keyboard script for $(uname -s)"
    ;;
esac
