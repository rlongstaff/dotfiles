#!/bin/sh
#
# Idempotent: re-link every LINKS entry, render colors.yaml/keys.yaml, then audit with
# check.sh. Run any time to catch up after a git pull, or as the tail of install.sh.
# One-stop shop for "something changed; fix it and/or catch up to the new version."

set -e
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=${1:-${TARGET:-$HOME}}
. "${SCRIPT_DIR}/scripts/lib.sh"

log "relinking ${TARGET} -> ${SCRIPT_DIR}"
run_script "${SCRIPT_DIR}/scripts/install.d/10-symlinks.sh" "${TARGET}"

log "rendering colors and keys"
"${SCRIPT_DIR}/scripts/colors/render.sh"
"${SCRIPT_DIR}/scripts/keyboard/render.sh"

log "checking packages"
# A decline at the Y/n prompt exits non-zero; don't let set -e abort the rest of the
# update over that -- check.sh below reports anything still missing.
case "$(uname -s)" in
  Linux)
    "${SCRIPT_DIR}/scripts/pkgs/deb.sh" --install-missing || true
    ;;
  Darwin)
    "${SCRIPT_DIR}/scripts/pkgs/mac.sh" --install-missing || true
    "${SCRIPT_DIR}/scripts/pkgs/mac-tweaks.sh" || true
    ;;
  *)
    log "no package step for $(uname -s)"
    ;;
esac

log "checking install"
run_script "${SCRIPT_DIR}/scripts/check.sh" "${TARGET}"
