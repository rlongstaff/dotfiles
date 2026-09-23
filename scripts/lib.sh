# Shared by install.sh, uninstall.sh and every script under scripts/.  Sourced, never run.
#
# Two roots, and every path in every script is spelled in terms of one of them:
#
#   SCRIPT_DIR  the repo checkout.  The caller sets it before sourcing, because a sourced
#               sh file cannot find itself.  Every script computes it from its own $0.
#   TARGET      the home directory being acted on.  $HOME unless the caller overrides it,
#               which is how a throwaway target (`./install.sh /tmp/fakehome`) works.
#
# The contract: TARGET holds symlinks, SCRIPT_DIR holds files.  Every managed path in
# TARGET is a symlink whose final target is inside SCRIPT_DIR, so editing "~/.vimrc" edits
# the checkout and git sees it.  No script writes a file into TARGET; a generated config
# is a repo file plus a LINKS entry.  scripts/check.sh enforces both halves.
#
# POSIX sh, bash 3.x safe -- macOS /bin/sh is bash 3.2.

REPO="dotfiles"
REPO_URL="https://github.com/rlongstaff/${REPO}"

: "${TARGET:=$HOME}"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')   # linux | darwin

INSTALL_CANARY="${TARGET}/.${REPO}_installed"   # exists => installed here
LOCAL_REPO="${TARGET}/.${REPO}"                 # convenience symlink to SCRIPT_DIR

# --------------------------------------------------------------------------------------
# LINKS: every symlink install.sh creates.  One per line:
#
#   <path under TARGET>   [<path under SCRIPT_DIR>]   [<os>]
#
# The second column defaults to the first.  The third restricts the entry to one OS
# (`linux` or `darwin`, as uname -s spells it in lower case).  Nested destinations are
# fine; the parent directory is created.  Add a line here, never an `ln` elsewhere.
#
# Link a config *directory* rather than a file inside it when the app reads more than one
# file there (kitty includes keys.conf).  Never both: a file entry under a linked
# directory resolves to the repo file itself, and 10-symlinks.sh would move it aside.
# --------------------------------------------------------------------------------------
LINKS="
.gitconfig
.gitignore
.tmux
.tmux.conf
.vim
.vimrc
.shell
.bashrc                                     .shell/.bashrc
.bash_profile                               .shell/.bash_profile
.profile                                    .shell/.profile
.zshrc                                      .shell/.zshrc
.zprofile                                   .shell/.zprofile
.config/alacritty
.config/kitty
.config/labwc                               .config/labwc                               linux
.Xresources                                 .Xresources                                 linux
Library/LaunchAgents/us.longstaff.keyboard.plist   Library/LaunchAgents/us.longstaff.keyboard.plist   darwin
"

# Files that, if found as real files in TARGET, ought to be brought under LINKS instead.
# check.sh reports them.  Includes the files older versions of these scripts generated.
CANDIDATES="
.inputrc
.screenrc
.Xdefaults
.xinitrc
.fluxbox/keys
.config/alacritty/keyboard.toml
.config/kitty/keyboard.conf
"

# Call "$1 dest src" for every LINKS entry that applies to this OS.  A here-doc rather
# than a pipe so the callback runs in this shell and can keep counters.
links_each() {
  while read -r dest src os; do
    [ -n "${dest}" ] || continue
    case "${dest}" in \#*) continue ;; esac
    [ -n "${src}" ] || src="${dest}"
    [ -z "${os}" ] || [ "${os}" = "${OS}" ] || continue
    "$1" "${dest}" "${src}"
  done <<EOM
${LINKS}
EOM
}

# Helpers ------------------------------------------------------------------------------

# Prefix every line with the calling script's name so interleaved module output reads.
: "${MODULE:=$(basename -- "${0:-dotfiles}" .sh)}"
log()  { echo "${MODULE}: $*"; }
warn() { echo "${MODULE}: WARNING $*" >&2; }

have() { which "$1" >/dev/null 2>&1; }

# Ask before a host mutation (installing packages, writing a system setting). Default
# yes on an empty answer; anything starting n/N declines. Used by scripts/pkgs/*.sh, which
# echo exactly what they are about to run before calling this.
confirm() {
  printf '%s [Y/n] ' "$1"
  read -r ans
  case "${ans}" in [Nn]*) return 1 ;; *) return 0 ;; esac
}

# True when TARGET is the real home.  Anything that changes the *live session* rather
# than a file (gsettings, setxkbmap, hidutil, launchctl, xrdb) is gated on this, so a
# throwaway target never reaches the desktop.
live_home() { [ "${TARGET}" = "${HOME}" ]; }

# Run a script with the shared roots in its environment.  Executable bit optional.
run_script() {
  SCRIPT_DIR="${SCRIPT_DIR}" TARGET="${TARGET}" BACKUP_DIR="${BACKUP_DIR:-}" sh "$@"
}
