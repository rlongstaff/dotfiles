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

The following is to pin ohmyzsh to a check-valve repo.  This allows for examination
of deltas without blindly installing things into your shell.

Install ohmyzsh:
  sh -c "\$(curl -fsSL https://raw.githubusercontent.com/rlongstaff/ohmyzsh/master/tools/install.sh)"

If a tmux server is already running it is still on the old config:
  tmux kill-server

CHECK YOUR .gitconfig [USER] SECTION!!!!
EOM
