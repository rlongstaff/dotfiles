#!/bin/sh
#
# Last step: audit what the earlier steps did.  See ../check.sh.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
. "${SCRIPT_DIR}/scripts/lib.sh"

run_script "${SCRIPT_DIR}/scripts/check.sh"
