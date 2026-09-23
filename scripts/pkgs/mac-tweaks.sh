#!/bin/sh
#
# macOS defaults(1) settings.  Two modes:
#
#   (no args)  apply every drifted setting below, after a Y/n confirm per setting;
#              already-correct settings are reported and left alone.
#   --check    read-only; lists drifted settings, exit 1 if any.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "${SCRIPT_DIR}/scripts/lib.sh"

[ "$(uname -s)" = "Darwin" ] || { log "not macOS; nothing to do"; exit 0; }

# One row per setting: <domain> <key> <type> <want>.
SETTINGS="
com.apple.desktopservices DSDontWriteNetworkStores bool TRUE
com.apple.desktopservices DSDontWriteUSBStores     bool TRUE
"

# defaults read prints 1/0 for a key written with -bool TRUE/FALSE; normalize both sides
# to that spelling before comparing.
norm() {
  case "$1" in
    TRUE|true|1) echo 1 ;;
    FALSE|false|0) echo 0 ;;
    *) echo "$1" ;;
  esac
}

settings_each() {
  while read -r domain key type want; do
    [ -n "${domain}" ] || continue
    "$1" "${domain}" "${key}" "${type}" "${want}"
  done <<EOM
${SETTINGS}
EOM
}

check_one() {
  domain="$1"; key="$2"; want="$4"
  got=$(defaults read "${domain}" "${key}" 2>/dev/null) || got="<unset>"
  if [ "$(norm "${got}")" = "$(norm "${want}")" ]; then
    ok=$((ok + 1))
  else
    echo "  DRIFT  ${domain} ${key}  (want ${want}, got ${got})"
    bad=$((bad + 1))
  fi
}

apply_one() {
  domain="$1"; key="$2"; type="$3"; want="$4"
  got=$(defaults read "${domain}" "${key}" 2>/dev/null) || got="<unset>"
  if [ "$(norm "${got}")" = "$(norm "${want}")" ]; then
    log "${domain} ${key}: already set"
    return 0
  fi
  log "about to run: defaults write ${domain} ${key} -${type} ${want}"
  if confirm "Apply this setting?"; then
    defaults write "${domain}" "${key}" -"${type}" "${want}"
  else
    warn "skipped ${domain} ${key}"
  fi
}

case "${1:-}" in
  --check)
    bad=0; ok=0
    settings_each check_one
    [ ${bad} -eq 0 ] || exit 1
    exit 0
    ;;
  "")
    settings_each apply_one
    ;;
  *)
    echo "usage: $0 [--check]" >&2
    exit 2
    ;;
esac
