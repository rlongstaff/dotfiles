#!/bin/bash
#
# macOS packages, Homebrew.  Mirrors deb.sh.  Three modes:
#
#   (no args)          full run: brew install the whole list.
#   --check            read-only; lists missing packages, exit 1 if any.
#   --install-missing  installs only what --check would list, after a Y/n confirm; a
#                       no-op (no brew call at all) when nothing is missing.  This is
#                       what update.sh calls, so a repeat run does nothing.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "${SCRIPT_DIR}/scripts/lib.sh"

PKGS=(
     bash-completion
     jq
     # mikefarah's Go yq, for scripts/keyboard/render.sh.  Homebrew's 'yq' formula *is*
     # this one -- no Debian-style naming collision with a python yq here, so leave it
     # 'yq', not 'yq-go'.
     yq
     tmux
     # Homebrew's vim already ships +python3, so no vim-nox equivalent is needed.
     vim
     zsh
     tealdeer
)

# No clipboard package: pbcopy/pbpaste ship with macOS, unlike deb.sh's wl-clipboard/xclip.
# No 'brew update'/'brew upgrade' step: unlike apt, 'brew install' does not need a separate
# repo-sync step first, so there is no heavier command for --install-missing to skip past.

have brew || { warn "brew not found; skipping"; exit 0; }

installed_brew() {
  brew list --formula "$1" >/dev/null 2>&1
}

missing_brew() {
  MISSING=()
  for p in "${PKGS[@]}"; do
    installed_brew "${p}" || MISSING+=("${p}")
  done
}

case "${1:-}" in
  --check)
    missing_brew
    for p in "${MISSING[@]}"; do
      echo "  MISSING  ${p}"
    done
    [ ${#MISSING[@]} -eq 0 ] || exit 1
    exit 0
    ;;
  --install-missing)
    missing_brew
    if [ ${#MISSING[@]} -eq 0 ]; then
      log "nothing to install"
      exit 0
    fi
    log "missing: ${MISSING[*]}"
    log "about to run: brew install ${MISSING[*]}"
    if confirm "Install these packages?"; then
      brew install "${MISSING[@]}"
    else
      warn "skipped"
      exit 1
    fi
    ;;
  "")
    log "about to run: brew install ${PKGS[*]}"
    if confirm "Install the full package list?"; then
      brew install "${PKGS[@]}"
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
