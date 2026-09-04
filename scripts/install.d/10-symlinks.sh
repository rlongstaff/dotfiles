#!/bin/sh
#
# Create every LINKS entry (scripts/lib.sh) as an absolute symlink into SCRIPT_DIR.
# A real file already in the way is moved into BACKUP_DIR first; a symlink is replaced.
# This is the only script that creates links, and nothing else writes into TARGET.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
. "${SCRIPT_DIR}/scripts/lib.sh"

: "${BACKUP_DIR:=${TARGET}/.${REPO}.bak.$(date "+%Y%m%d-%H%M%S")}"
mkdir -p "${BACKUP_DIR}"

# Convenience link so `cd ~/.dotfiles` lands in the checkout.
[ -e "${LOCAL_REPO}" ] || ln -s "${SCRIPT_DIR}" "${LOCAL_REPO}"

n=0
link_one() {
  dest="${TARGET}/$1"
  src="${SCRIPT_DIR}/$2"
  if [ ! -e "${src}" ]; then
    warn "no such file in repo: $2 (LINKS entry skipped)"
    return 0
  fi
  mkdir -p "$(dirname -- "${dest}")"
  if [ -e "${dest}" ] && [ ! -L "${dest}" ]; then
    mkdir -p "${BACKUP_DIR}/$(dirname -- "$1")"
    mv "${dest}" "${BACKUP_DIR}/$1"
  fi
  ln -sfn "${src}" "${dest}"
  n=$((n + 1))
}
links_each link_one

log "linked ${n} entries into ${TARGET} -> ${SCRIPT_DIR}"
