#!/bin/sh
#
# Remove the symlinks install.sh made (scripts/lib.sh LINKS).  Takes the same optional
# target dir.  Nothing is restored: copy what you want back from
# ~/.dotfiles.bak.<timestamp> by hand.

set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=${1:-$HOME}
. "${SCRIPT_DIR}/scripts/lib.sh"

if [ ! -f "${INSTALL_CANARY}" ]; then
  echo "${REPO} not installed in ${TARGET}."
  exit 1
fi

unlink_one() {
  link="${TARGET}/$1"
  # Only ever remove a symlink; a real file in the way is not ours.
  [ -L "${link}" ] && rm "${link}"
  return 0
}
links_each unlink_one
[ -L "${LOCAL_REPO}" ] && rm "${LOCAL_REPO}"
rm "${INSTALL_CANARY}"
echo "${REPO} uninstalled from ${TARGET}"
