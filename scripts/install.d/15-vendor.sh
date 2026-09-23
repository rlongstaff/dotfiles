#!/bin/sh
#
# Check out the git submodules under vendor/ (vim plugins; .vim/bundle/<name> links to
# them) at the commits this repo pins.  Writes only inside SCRIPT_DIR.
#
# A tarball install has no git metadata, so there is nothing to pin against: warn and skip.
# vim degrades gracefully without the plugins.  To move a submodule to upstream's latest,
# by hand:  git submodule update --remote vendor/<name>, then commit the new pin.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
. "${SCRIPT_DIR}/scripts/lib.sh"

VENDOR_DIR="${SCRIPT_DIR}/vendor"

if ! have git; then
  warn "git not found; vendor/ submodules not checked out"
  exit 0
fi
if ! git -C "${SCRIPT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  warn "${SCRIPT_DIR} is not a git checkout (tarball install); vendor/ submodules skipped"
  exit 0
fi

git -C "${SCRIPT_DIR}" submodule sync --quiet -- "${VENDOR_DIR}"
git -C "${SCRIPT_DIR}" submodule update --init --recursive -- "${VENDOR_DIR}"

log "vendor/ submodules at their pinned commits"
git -C "${SCRIPT_DIR}" submodule status -- "${VENDOR_DIR}" | sed "s/^/${MODULE}:   /"
