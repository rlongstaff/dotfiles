#!/usr/bin/env bash
# Canonical key spelling <-> each app's spelling.  Sourced by render.sh (forward) and
# capture.sh (inverse).  Keep each from_* next to its forward twin so they cannot drift.
# bash 3.2 safe.  No side effects on source.

# split KEY -> sets MODS ("ctrl alt ...") and BASE.  The base is whatever follows the
# last '+' ('ctrl++' is ctrl and '+'), so 'alt+-' and 'alt+\' parse; a bare key has no modifiers.
split() {
  case "$1" in
    *++) BASE=+; MODS=$(printf '%s' "${1%++}" | tr '+' ' ') ;;
    *+?*) BASE=${1##*+}; MODS=$(printf '%s' "${1%+*}" | tr '+' ' ') ;;
    *)    BASE=$1; MODS="" ;;
  esac
}

has_mod() { case " ${MODS} " in *" $1 "*) return 0 ;; esac; return 1; }

# validate KEY -> prints a reason and returns 1 when KEY breaks the spelling rules.
validate() {
  split "$1"
  last=0
  for m in ${MODS}; do
    case "${m}" in
      ctrl) i=1 ;; alt) i=2 ;; shift) i=3 ;; super) i=4 ;;
      *) echo "unknown modifier '${m}'"; return 1 ;;
    esac
    [ "${i}" -gt "${last}" ] || { echo "modifiers out of order (ctrl alt shift super)"; return 1; }
    last=${i}
  done
  case "${BASE}" in
    [a-z0-9]|left|right|up|down|home|end|pageup|pagedown|tab|enter|space|backspace) ;;
    delete|esc|f[1-9]|f1[0-2]|XF86*|mouse-left|mouse-right|wheel|capslock|alt) ;;
    [A-Z]) echo "upper-case letter; write shift explicitly"; return 1 ;;
    ?) case "${BASE}" in [[:punct:]]) ;; *) echo "unknown key '${BASE}'"; return 1 ;; esac ;;
    *) echo "unknown key '${BASE}'"; return 1 ;;
  esac
}

upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }

# Named keys, per app.  Anything not listed is a single character, passed as is.
tmux_name() {
  case "$1" in
    left) echo Left ;; right) echo Right ;; up) echo Up ;; down) echo Down ;;
    home) echo Home ;; end) echo End ;; pageup) echo PPage ;; pagedown) echo NPage ;;
    tab) echo Tab ;; enter) echo Enter ;; space) echo Space ;; backspace) echo BSpace ;;
    delete) echo DC ;; esc) echo Escape ;; f[0-9]*) upper "$1" ;; *) printf '%s\n' "$1" ;;
  esac
}
vim_name() {
  case "$1" in
    left) echo Left ;; right) echo Right ;; up) echo Up ;; down) echo Down ;;
    home) echo Home ;; end) echo End ;; pageup) echo PageUp ;; pagedown) echo PageDown ;;
    tab) echo Tab ;; enter) echo CR ;; space) echo Space ;; backspace) echo BS ;;
    delete) echo Del ;; esc) echo Esc ;; f[0-9]*) upper "$1" ;; *) printf '%s\n' "$1" ;;
  esac
}
gtk_name() {
  case "$1" in
    left) echo Left ;; right) echo Right ;; up) echo Up ;; down) echo Down ;;
    tab) echo Tab ;; enter) echo Return ;; space) echo space ;; esc) echo Escape ;;
    +) echo plus ;; -) echo minus ;;
    f[0-9]*) upper "$1" ;; *) printf '%s\n' "$1" ;;
  esac
}
kitty_name() {
  case "$1" in
    pageup) echo page_up ;; pagedown) echo page_down ;; esc) echo escape ;;
    =) echo equal ;; -) echo minus ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# tmux_keys KEY -> one tmux key name per line (alt+shift+tab has two encodings).
tmux_keys() {
  split "$1"
  if [ "$1" = "alt+shift+tab" ]; then echo M-BTab; echo M-S-Tab; return; fi
  p=""
  has_mod ctrl && p="${p}C-"
  has_mod alt && p="${p}M-"
  if has_mod shift; then
    case "${BASE}" in [a-z]) printf '%s%s\n' "${p}" "$(upper "${BASE}")"; return ;; esac
    p="${p}S-"
  fi
  printf '%s%s\n' "${p}" "$(tmux_name "${BASE}")"
}

# tmux_q NAME -> NAME quoted when the config parser would otherwise eat part of it.
tmux_q() {
  case "$1" in
    *\'*) printf '"%s"\n' "$1" ;;
    *[\\\"\#\;\$\~]*) printf "'%s'\n" "$1" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

vim_key() {
  split "$1"
  p=""
  has_mod ctrl && p="${p}C-"
  has_mod alt && p="${p}M-"
  b=$(vim_name "${BASE}")
  if has_mod shift; then
    case "${BASE}" in [a-z]) b=$(upper "${BASE}") ;; *) p="${p}S-" ;; esac
  fi
  if [ -z "${p}" ] && [ "${#b}" -eq 1 ]; then printf '%s\n' "${b}"; else printf '<%s%s>\n' "${p}" "${b}"; fi
}

kitty_key() {
  split "$1"
  p=""
  for m in ${MODS}; do p="${p}${m}+"; done
  printf '%s%s\n' "${p}" "$(kitty_name "${BASE}")"
}

labwc_key() {
  split "$1"
  p=""
  has_mod super && p="${p}W-"
  has_mod ctrl && p="${p}C-"
  has_mod alt && p="${p}A-"
  has_mod shift && p="${p}S-"
  printf '%s%s\n' "${p}" "$(gtk_name "${BASE}")"
}

gtk_key() {
  split "$1"
  p=""
  has_mod ctrl && p="${p}<Control>"
  has_mod alt && p="${p}<Alt>"
  has_mod shift && p="${p}<Shift>"
  has_mod super && p="${p}<Super>"
  printf '%s%s\n' "${p}" "$(gtk_name "${BASE}")"
}

# canon "MODS" BASE -> canonical key.  MODS in any order, drawn from ctrl alt shift super.
canon() {
  out=""
  for m in ctrl alt shift super; do
    case " $1 " in *" ${m} "*) out="${out}${m}+" ;; esac
  done
  printf '%s%s\n' "${out}" "$2"
}

# lower BASE -> canonical base for a named key, or the char itself.
_base_from() {   # app-neutral names already lower-cased
  case "$1" in
    pageup|page_up|prior) echo pageup ;; pagedown|page_down|next) echo pagedown ;;
    return|enter|cr) echo enter ;; escape|esc) echo esc ;; bs|backspace) echo backspace ;;
    del|delete|dc) echo delete ;; space) echo space ;; tab) echo tab ;;
    left|right|up|down|home|end) echo "$1" ;;
    f[1-9]|f1[0-2]) echo "$1" ;;
    ?) echo "$1" ;;
    *) return 1 ;;
  esac
}

# _wm_base NAME: base key from a gtk/labwc key name.  XF86 keysyms keep their case (keys.yaml
# writes them as is); plus and minus are the gtk names of + and -.
_wm_base() {
  case "$1" in
    XF86?*) printf '%s\n' "$1" ;;
    plus|Plus) echo + ;; minus|Minus) echo - ;;
    *) _base_from "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" ;;
  esac
}

# from_tmux NAME -> canonical.  Handles list-keys escaping and the two shift-Tab names.
from_tmux() {
  n=$1
  case "${n}" in M-BTab|M-S-Tab) echo alt+shift+tab; return 0 ;; BTab) echo shift+tab; return 0 ;; esac
  # list-keys prints '\' before \ " % ; # $ ~ : drop one level of escaping per key.
  un=""
  mods=""
  while :; do
    case "${n}" in
      C-?*) mods="${mods} ctrl"; n=${n#C-} ;;
      M-?*) mods="${mods} alt";  n=${n#M-} ;;
      S-?*) mods="${mods} shift"; n=${n#S-} ;;
      *) break ;;
    esac
  done
  case "${n}" in \\?) n=${n#\\} ;; esac
  case "${n}" in
    [A-Z]) mods="${mods} shift"; n=$(printf '%s' "${n}" | tr '[:upper:]' '[:lower:]') ;;
    PPage) n=pageup ;; NPage) n=pagedown ;; BSpace) n=backspace ;; DC) n=delete ;;
    Enter|Tab|Space|Escape|Left|Right|Up|Down|Home|End|F[0-9]*)
       n=$(printf '%s' "${n}" | tr '[:upper:]' '[:lower:]') ;;
    ?) ;;
    *) return 1 ;;
  esac
  b=$(_base_from "${n}") || return 1
  canon "${mods}" "${b}"
}

# from_vim LHS -> canonical.  Single char: letter case implies shift.
from_vim() {
  l=$1
  case "${l}" in
    '<'?*'>')
      inner=${l#<}; inner=${inner%>}
      mods=""
      while :; do
        case "${inner}" in
          C-?*) mods="${mods} ctrl"; inner=${inner#C-} ;;
          M-?*|A-?*) mods="${mods} alt"; inner=${inner#?-} ;;
          S-?*) mods="${mods} shift"; inner=${inner#S-} ;;
          D-?*) mods="${mods} super"; inner=${inner#D-} ;;
          *) break ;;
        esac
      done
      case "${inner}" in
        [A-Z]) mods="${mods} shift"; inner=$(printf '%s' "${inner}" | tr '[:upper:]' '[:lower:]') ;;
      esac
      low=$(printf '%s' "${inner}" | tr '[:upper:]' '[:lower:]')
      b=$(_base_from "${low}") || return 1
      canon "${mods}" "${b}" ;;
    [A-Z]) canon shift "$(printf '%s' "${l}" | tr '[:upper:]' '[:lower:]')" ;;
    ?) canon "" "${l}" ;;
    *) return 1 ;;
  esac
}

# from_kitty "ctrl+shift+page_up" -> canonical.  Modifier words in any order.
from_kitty() {
  s=$1; mods=""
  case "${s}" in *+?*) b=${s##*+}; ms=${s%+*} ;; *) b=${s}; ms="" ;; esac
  for m in $(printf '%s' "${ms}" | tr '+' ' '); do
    case "${m}" in ctrl|control) mods="${mods} ctrl" ;; alt|opt|option) mods="${mods} alt" ;;
      shift) mods="${mods} shift" ;; super|cmd|command) mods="${mods} super" ;; *) return 1 ;; esac
  done
  case "${b}" in equal|EQUAL) b="=" ;; minus|MINUS) b="-" ;; esac
  b=$(_base_from "$(printf '%s' "${b}" | tr '[:upper:]' '[:lower:]')") || return 1
  canon "${mods}" "${b}"
}

# from_gtk "<Super><Shift>Tab" -> canonical (also gnome-terminal and gsettings values).
from_gtk() {
  s=$1; mods=""
  while :; do
    case "${s}" in
      '<Control>'*|'<Primary>'*) mods="${mods} ctrl"; s=${s#<*>} ;;
      '<Alt>'*)   mods="${mods} alt";   s=${s#<*>} ;;
      '<Shift>'*) mods="${mods} shift"; s=${s#<*>} ;;
      '<Super>'*|'<Meta>'*|'<Hyper>'*) mods="${mods} super"; s=${s#<*>} ;;
      *) break ;;
    esac
  done
  b=$(_wm_base "${s}") || return 1
  canon "${mods}" "${b}"
}

# from_labwc "W-C-A-S-name" -> canonical.
from_labwc() {
  s=$1; mods=""
  while :; do
    case "${s}" in
      W-?*) mods="${mods} super"; s=${s#W-} ;;
      C-?*) mods="${mods} ctrl";  s=${s#C-} ;;
      A-?*) mods="${mods} alt";   s=${s#A-} ;;
      S-?*) mods="${mods} shift"; s=${s#S-} ;;
      *) break ;;
    esac
  done
  b=$(_wm_base "${s}") || return 1
  canon "${mods}" "${b}"
}

# from_iterm2 "0xUNI-0xMODS-0xKEYCODE": NSEvent flags shift 0x20000, ctrl 0x40000,
# option 0x80000, cmd 0x100000.  0xf700.. are the NSEvent function-key code points.
from_iterm2() {
  uni=${1%%-*}; rest=${1#*-}; fl=${rest%%-*}
  fl=$((fl)); mods=""
  [ $((fl & 0x40000))  -eq 0 ] || mods="${mods} ctrl"
  [ $((fl & 0x80000))  -eq 0 ] || mods="${mods} alt"
  [ $((fl & 0x20000))  -eq 0 ] || mods="${mods} shift"
  [ $((fl & 0x100000)) -eq 0 ] || mods="${mods} super"
  u=$((uni))
  case "${u}" in
    63232) b=up ;; 63233) b=down ;; 63234) b=left ;; 63235) b=right ;;
    63272) b=delete ;; 63273) b=home ;; 63275) b=end ;; 63276) b=pageup ;; 63277) b=pagedown ;;
    6323[6-9]|6324[0-7]) b="f$((u - 63235))" ;;
    9) b=tab ;; 13) b=enter ;; 27) b=esc ;; 32) b=space ;; 127) b=backspace ;;
    *) [ "${u}" -ge 33 ] && [ "${u}" -le 126 ] || return 1
       b=$(printf "\\$(printf '%03o' "${u}")") ;;
  esac
  case "${b}" in [A-Z]) mods="${mods} shift"; b=$(printf '%s' "${b}" | tr '[:upper:]' '[:lower:]') ;; esac
  canon "${mods}" "${b}"
}
