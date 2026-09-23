#!/bin/sh
#
# Things the install cannot do for you.  Last, so they are the final thing on screen.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
. "${SCRIPT_DIR}/scripts/lib.sh"

cat <<EOM

Packages are not installed by install.sh.  One script per platform, run by hand:
  ${SCRIPT_DIR}/scripts/pkgs/deb.sh          Debian / Ubuntu / WSL2
  ${SCRIPT_DIR}/scripts/pkgs/mac-tweaks.sh   macOS defaults(1) only

If a tmux server is already running it is still on the old config:
  tmux kill-server

EDIT ${TARGET}/.gitconfig.local WITH YOUR NAME AND EMAIL!!!!
EOM
