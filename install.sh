#!/bin/sh
#
# Bootstrap: find or fetch the repo, then run scripts/install.d/*.sh in order.
#
# This file is deliberately thin so it can be curl'd on its own: it has to work before
# scripts/ exists.  Everything that needs scripts/lib.sh lives in scripts/install.d/.

set -e

REPO="dotfiles"
REPO_URL="https://github.com/rlongstaff/${REPO}"

help() {
  echo "Usage: $0 [target_dir]"
  echo
  echo "Install in your home directory:"
  echo "  Option 1) curl -Ls ${REPO_URL}/install.sh | sh"
  echo "  Option 2) curl -LOs ${REPO_URL}/install.sh \\"
  echo "            # Review the code! \\"
  echo "            ./install.sh"
  echo "  Option 3) git clone ${REPO_URL} \\ "
  echo "            ${REPO}/install.sh"
  echo
  echo "Install in a different directory (dry run against a throwaway home):"
  echo "            ./install.sh /tmp/fakehome"
  echo
  echo "Modules run, in order:"
  ls "$(dirname -- "$0")/scripts/install.d" 2>/dev/null | sed 's/^/            /'
  exit 0
}

if [ ! -t 0 ]; then
  # stdin is not a terminal, likely piped
  echo "STOP PIPING RANDOM TEXT FROM THE INTERNET INTO YOUR SHELL!"
fi

TARGET=$1
if [ -z "${TARGET}" ]; then
  TARGET=$HOME
elif [ "${TARGET}" = "help" ] || [ "${TARGET}" = "--help" ] || [ "${TARGET}" = "-h" ]; then
  help
else
  mkdir -p "${TARGET}"
  TARGET=$(realpath "${TARGET}")
fi

INSTALL_CANARY="${TARGET}/.${REPO}_installed"
LOCAL_REPO="${TARGET}/.${REPO}"
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
BACKUP_DIR="${TARGET}/.${REPO}.bak.${TIMESTAMP}"

if [ -f "${INSTALL_CANARY}" ]; then
  echo "${REPO} already installed: ${INSTALL_CANARY}"
  echo "Re-run a single step with:  scripts/install.d/<module>.sh [target_dir]"
  exit 1
fi

# Set up the backup directory; an existing ~/.dotfiles is the first thing into it.
if [ -e "${LOCAL_REPO}" ]; then
  mv "${LOCAL_REPO}" "${BACKUP_DIR}"
else
  mkdir -p "${BACKUP_DIR}"
fi

# Do we have our friends?  SCRIPT_DIR is the repo root once this block is done.
SCRIPT_DIR=$(realpath "$(dirname -- "$0")")
if [ -f "${SCRIPT_DIR}/scripts/lib.sh" ]; then
  # Yup, use this checkout as home base
  ln -sf "${SCRIPT_DIR}" "${LOCAL_REPO}"
else
  # Nope, grab them
  TMPDIR=$(mktemp -d)
  curl -Ls "${REPO_URL}/archive/refs/heads/main.tar.gz" \
    | tar xz -C "${TMPDIR}"
  mv "${TMPDIR}/${REPO}-main" "${LOCAL_REPO}"
  rmdir "${TMPDIR}"
  SCRIPT_DIR=$(realpath "${LOCAL_REPO}")
fi

export SCRIPT_DIR TARGET BACKUP_DIR

# Run the modules.  A failing module is reported and the rest still run: the symlinks
# are the install, and a keyboard step that cannot reach a display should not undo them.
failed=""
for module in "${SCRIPT_DIR}"/scripts/install.d/*.sh; do
  echo "==> $(basename -- "${module}")"
  if ! sh "${module}"; then
    failed="${failed} $(basename -- "${module}")"
  fi
done

# Ditch the backup if it's empty
if [ -z "$(ls -A "${BACKUP_DIR}")" ]; then
  rmdir "${BACKUP_DIR}"
else
  echo "Replaced files backed up to ${BACKUP_DIR}"
fi

touch "${INSTALL_CANARY}"

if [ -n "${failed}" ]; then
  echo "install: FAILED modules:${failed}" >&2
  echo "install: re-run each with  scripts/install.d/<module>.sh ${TARGET}" >&2
  exit 1
fi
