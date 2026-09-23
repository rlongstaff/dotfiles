#!/bin/bash
#
# Debian / Ubuntu / WSL2 packages.  Three modes:
#
#   (no args)          full run: apt-get update && upgrade && install the whole list.
#   --check            read-only; lists missing packages, exit 1 if any.
#   --install-missing  installs only what --check would list, after a Y/n confirm; a
#                       no-op (no sudo call at all) when nothing is missing.  This is
#                       what update.sh calls, so a repeat run does nothing.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "${SCRIPT_DIR}/scripts/lib.sh"

PKGS=(
     bash-completion
     jq
     # mikefarah's Go yq, for scripts/keyboard/render.sh.  NOT the 'yq' package, which is
     # the python jq wrapper with the same name and a different language.
     yq-go
     wamerican
     tmux
     # vim-nox, not vim: the debugger plugin (vimspector) needs vim built +python3, and
     # Debian's plain 'vim' package is not.  Same vim otherwise, no GUI.
     vim-nox
     zsh
     # Clipboard tools, so a vim yank (`yy`) reaches the system clipboard -- vim is built
     # -clipboard here, so it pipes to one of these.  Mouse copy does not need them: that
     # is Shift-drag plus Cmd-C, handled entirely by the terminal emulator.  One per
     # session type; installing both is harmless, since .vimrc picks one at runtime.
     wl-clipboard
     tealdeer
     xclip
)

# Go tooling for vim is not packaged here: Debian's gopls and delve trail upstream by
# many releases.  With Go installed, both land in $(go env GOPATH)/bin:
#   go install golang.org/x/tools/gopls@latest
#   go install github.com/go-delve/delve/cmd/dlv@latest

have dpkg-query || { warn "dpkg-query not found; skipping"; exit 0; }

installed_deb() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^install ok installed'
}

missing_deb() {
  MISSING=()
  for p in "${PKGS[@]}"; do
    installed_deb "${p}" || MISSING+=("${p}")
  done
}

case "${1:-}" in
  --check)
    missing_deb
    for p in "${MISSING[@]}"; do
      echo "  MISSING  ${p}"
    done
    [ ${#MISSING[@]} -eq 0 ] || exit 1
    exit 0
    ;;
  --install-missing)
    missing_deb
    if [ ${#MISSING[@]} -eq 0 ]; then
      log "nothing to install"
      exit 0
    fi
    log "missing: ${MISSING[*]}"
    log "about to run: sudo apt-get install -y ${MISSING[*]}"
    if confirm "Install these packages?"; then
      sudo apt-get install -y "${MISSING[@]}"
    else
      warn "skipped"
      exit 1
    fi
    ;;
  "")
    log "about to run: sudo apt-get update && sudo apt-get upgrade && sudo apt-get install ${PKGS[*]}"
    if confirm "Update, upgrade and install the full package list?"; then
      sudo apt-get update
      sudo apt-get upgrade
      sudo apt-get install "${PKGS[@]}"
    else
      warn "skipped"
      exit 1
    fi
    ;;
  *)
    echo "usage: $0 [--check|--install-missing]" >&2
    exit 2
    ;;
esac
