#!/bin/sh
#
# Comfort layout for TARGET: ~/docs, ~/prj (+ ~/src alias), ~/bin, ~/tmp, and an ssh
# skeleton with the right modes.  Never touches anything that already exists.

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

log "comfort dirs in place"
