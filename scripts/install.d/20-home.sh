#!/bin/sh
#
# Comfort layout for TARGET: ~/docs, ~/prj (+ ~/src alias), ~/bin, ~/tmp, an ssh
# skeleton with the right modes, and a ~/.gitconfig.local seed.  Never touches
# anything that already exists.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
. "${SCRIPT_DIR}/scripts/lib.sh"

# Get our ~/docs folders uniform across systems
if [ ! -e "${TARGET}/docs" ]; then
  if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    # Windows Subsystem for Linux (WSL)
    WINUSER=$(perl -e 'use Env; ($_) = ${PATH} =~ /Users\/([^\/]+)\/AppData/; print;')
    ln -s "/mnt/c/Users/${WINUSER}/Documents" "${TARGET}/docs"
    ln -s "/mnt/c/Users/${WINUSER}/Downloads" "${TARGET}/downloads"
    ln -s "/mnt/c/Users/${WINUSER}"           "${TARGET}/win"
  elif [ -d "${TARGET}/Documents" ]; then
    # Regular Linux or macOS
    ln -s Documents "${TARGET}/docs"
  fi
fi
mkdir -p "${TARGET}/docs/notes"

for i in bin tmp prj; do
  mkdir -p "${TARGET}/${i}"
done

# Basic ssh skel
if [ ! -d "${TARGET}/.ssh" ]; then
  mkdir -p "${TARGET}/.ssh"
  chmod 700 "${TARGET}/.ssh"
fi
if [ ! -f "${TARGET}/.ssh/authorized_keys" ]; then
  touch "${TARGET}/.ssh/authorized_keys"
  chmod 600 "${TARGET}/.ssh/authorized_keys"
fi

# ~/src -> ~/prj; ignore if ~/src already exists
[ -e "${TARGET}/src" ] || ln -s prj "${TARGET}/src"

# golang likes to have things this way
mkdir -p "${TARGET}/src/github.com"

# git identity: .gitconfig (repo, symlinked) includes this, but it's per-machine data,
# not config, so it lives outside the repo and is never overwritten once it exists.
if [ ! -e "${TARGET}/.gitconfig.local" ]; then
  cp "${SCRIPT_DIR}/.gitconfig.local.example" "${TARGET}/.gitconfig.local"
  log "wrote ${TARGET}/.gitconfig.local - edit it with your name and email"
fi

log "comfort dirs in place"
