#!/bin/sh
#
# Audit the install.  Run any time, or as the last install step (install.d/95-check.sh).
#
#   1. Every LINKS entry (scripts/lib.sh) is a symlink in TARGET resolving into SCRIPT_DIR.
#   2. Nothing in CANDIDATES sits in TARGET as an unmanaged real file.
#   3. No script under scripts/ writes into TARGET directly: the only sanctioned way to
#      put a file there is a repo file plus a LINKS entry.
#
# Exit 1 if anything is wrong, so it can gate a CI job or a shell prompt.

set -e
: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}"
TARGET=${1:-${TARGET:-$HOME}}
. "${SCRIPT_DIR}/scripts/lib.sh"

# Scripts allowed to reference TARGET in a write position.  10-symlinks makes the links;
# 20-home makes empty comfort dirs and the ssh skeleton, which are not config.
WRITE_ALLOWED="install.d/10-symlinks.sh install.d/20-home.sh"

bad=0
ok=0

# Resolve a symlink chain to its final path without needing GNU realpath.
resolve() {
  p="$1"; i=0
  while [ -L "${p}" ] && [ ${i} -lt 32 ]; do
    t=$(readlink "${p}")
    case "${t}" in /*) p="${t}" ;; *) p="$(dirname -- "${p}")/${t}" ;; esac
    i=$((i + 1))
  done
  (CDPATH= cd -- "$(dirname -- "${p}")" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$(basename -- "${p}")") \
    || printf '%s\n' "${p}"
}

REAL_SCRIPT_DIR=$(CDPATH= cd -- "${SCRIPT_DIR}" && pwd -P)

check_link() {
  dest="${TARGET}/$1"
  want="${REAL_SCRIPT_DIR}/$2"
  if [ ! -e "${SCRIPT_DIR}/$2" ]; then
    echo "  MISSING IN REPO  $1  (LINKS names $2, which does not exist)"
    bad=$((bad + 1))
  elif [ -L "${dest}" ]; then
    got=$(resolve "${dest}")
    if [ "${got}" = "${want}" ]; then
      ok=$((ok + 1))
    else
      case "${got}" in
        "${REAL_SCRIPT_DIR}"/*) echo "  WRONG FILE       $1 -> ${got}  (want $2)" ;;
        *)                      echo "  OUTSIDE REPO     $1 -> ${got}" ;;
      esac
      bad=$((bad + 1))
    fi
  elif [ -e "${dest}" ]; then
    echo "  UNMANAGED        $1  (real file; should be a link to $2)"
    bad=$((bad + 1))
  else
    echo "  NOT LINKED       $1"
    bad=$((bad + 1))
  fi
}

echo "links: ${TARGET} -> ${REAL_SCRIPT_DIR}"
links_each check_link
echo "  ${ok} ok"

echo "candidates: real files in ${TARGET} that could be managed here"
found=0
for c in ${CANDIDATES}; do
  if [ -e "${TARGET}/${c}" ] && [ ! -L "${TARGET}/${c}" ]; then
    echo "  $c"
    found=$((found + 1))
  fi
done
[ ${found} -eq 0 ] && echo "  none"

echo "scripts: direct writes into TARGET"
# A redirection or cp/mv/tee/ln/mkdir/touch whose operand starts with ${TARGET},
# ${CONFIG_DIR}, ${LOCAL_REPO} or $HOME.  Comment lines are stripped first.
writes=0
for f in $(cd "${SCRIPT_DIR}/scripts" && find . -name '*.sh' | sed 's|^\./||' | sort); do
  case " ${WRITE_ALLOWED} " in *" ${f} "*) continue ;; esac
  hits=$(sed 's/#.*$//' "${SCRIPT_DIR}/scripts/${f}" \
    | grep -nE '(>>?[[:space:]]*"?\$\{?(TARGET|CONFIG_DIR|LOCAL_REPO|HOME)\b)|((cp|mv|tee|ln|mkdir|touch|sed -i|install)[^|;&]*"?\$\{?(TARGET|CONFIG_DIR|LOCAL_REPO|HOME)\b)' \
    || true)
  if [ -n "${hits}" ]; then
    echo "  ${f}:"
    echo "${hits}" | sed 's/^/    /'
    writes=$((writes + 1))
  fi
done
[ ${writes} -eq 0 ] && echo "  none"
bad=$((bad + writes))

echo "packages and settings: ${OS}"
case "${OS}" in
  linux)
    "${SCRIPT_DIR}/scripts/pkgs/deb.sh" --check || bad=$((bad + 1))
    ;;
  darwin)
    "${SCRIPT_DIR}/scripts/pkgs/mac.sh" --check || bad=$((bad + 1))
    "${SCRIPT_DIR}/scripts/pkgs/mac-tweaks.sh" --check || bad=$((bad + 1))
    ;;
  *)
    echo "  no package/setting check for ${OS}"
    ;;
esac

if [ ${bad} -gt 0 ]; then
  log "${bad} problem(s)"
  exit 1
fi
log "all good"
