#!/usr/bin/env bash
# Round-trip every forward spelling back to canonical.  No apps required.
set -eu
set -f
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "${SCRIPT_DIR}/scripts/keyboard/keys-lib.sh"

FAIL=0
eq() { [ "$2" = "$3" ] || { echo "FAIL $1: want '$2' got '$3'"; FAIL=1; }; }

KEYS='ctrl+x alt+h alt+shift+h alt+shift+tab ctrl+alt+left super+tab shift+super+tab alt+enter
alt+backspace f5 shift+f11 ctrl+f5 alt+- alt+, alt+. alt+[ alt+] alt+0 super+1 pageup ctrl+home
ctrl+delete alt+space alt+esc a z 5 super+left ctrl+shift+f5'
for k in ${KEYS}; do
  validate "${k}" >/dev/null || { echo "FAIL corpus: ${k} invalid"; FAIL=1; continue; }
  # tmux and vim cannot express super, so their forward forms drop it.
  case "${k}" in *super*) ;; *)
    for t in $(tmux_keys "${k}"); do eq "tmux ${k}" "${k}" "$(from_tmux "${t}")"; done
    eq "vim ${k}"   "${k}" "$(from_vim "$(vim_key "${k}")")" ;;
  esac
  eq "kitty ${k}" "${k}" "$(from_kitty "$(kitty_key "${k}")")"
  eq "gtk ${k}"   "${k}" "$(from_gtk "$(gtk_key "${k}")")"
  eq "labwc ${k}" "${k}" "$(from_labwc "$(labwc_key "${k}")")"
done

# Backslash, quote, percent: the forms tmux list-keys prints are escaped.
eq 'tmux bs'    'alt+\' "$(from_tmux 'M-\\')"
eq 'tmux bs2'   '\'     "$(from_tmux '\\')"
eq 'tmux dq'    '"'     "$(from_tmux '\"')"
eq 'tmux pct'   '%'     "$(from_tmux '\%')"
eq 'tmux semi'  'alt+;' "$(from_tmux 'M-\;')"
eq 'tmux btab'  'alt+shift+tab' "$(from_tmux 'M-BTab')"
eq 'tmux Hs'    'alt+shift+h'   "$(from_tmux 'M-H')"
eq 'tmux dc'    'delete'        "$(from_tmux 'DC')"
eq 'tmux np'    'pagedown'      "$(from_tmux 'NPage')"
eq 'vim cr'     'enter'         "$(from_vim '<CR>')"
eq 'vim lt'     'shift+f11'     "$(from_vim '<S-F11>')"
eq 'kitty pg'   'pageup'        "$(from_kitty 'page_up')"
eq 'gtk ret'    'super+enter'   "$(from_gtk '<Super>Return')"
# iTerm2: Cmd+T, Opt+Left, Shift+Cmd+]
eq 'iterm cmdt'   'super+t'      "$(from_iterm2 '0x74-0x100000-0x11')"
eq 'iterm optlf'  'alt+left'     "$(from_iterm2 '0xf702-0x280000-0x7b')"
eq 'iterm shcmd]' 'shift+super+]' "$(from_iterm2 '0x5d-0x120000-0x1e')"
eq 'iterm f1'     'f1'           "$(from_iterm2 '0xf704-0x0-0x7a')"
eq 'iterm f12'    'f12'          "$(from_iterm2 '0xf70f-0x0-0x6f')"
eq 'iterm sf11'   'shift+f11'    "$(from_iterm2 '0xf70e-0x20000-0x67')"
eq 'iterm cf5'    'ctrl+f5'      "$(from_iterm2 '0xf708-0x40000-0x60')"
eq 'iterm del'    'delete'       "$(from_iterm2 '0xf728-0x0-0x75')"
eq 'iterm home'   'home'         "$(from_iterm2 '0xf729-0x0-0x73')"
eq 'iterm end'    'end'          "$(from_iterm2 '0xf72b-0x0-0x77')"
eq 'iterm pgup'   'pageup'       "$(from_iterm2 '0xf72c-0x0-0x74')"
eq 'iterm pgdn'   'pagedown'     "$(from_iterm2 '0xf72d-0x0-0x79')"
out=$(from_iterm2 '0xf710-0x0-0x0' 2>/dev/null) && { echo "FAIL iterm f13 mapped"; FAIL=1; }
eq 'iterm f13 empty' '' "${out}"

# Unmappable returns 1 with no output.
out=$(from_tmux 'MouseDown1Pane' 2>/dev/null) && { echo "FAIL mouse mapped"; FAIL=1; }
eq 'unmapped empty' '' "${out}"

# XF86 keysyms pass through verbatim (keys.yaml uses them as written); plus/minus are gtk names.
eq 'labwc xf86'       'XF86AudioMute'              "$(from_labwc XF86AudioMute)"
eq 'labwc c-xf86'     'ctrl+XF86AudioMute'         "$(from_labwc C-XF86AudioMute)"
eq 'gtk alt xf86'     'alt+XF86AudioRaiseVolume'   "$(from_gtk '<Alt>XF86AudioRaiseVolume')"
eq 'gtk xf86 bright'  'XF86MonBrightnessUp'        "$(from_gtk 'XF86MonBrightnessUp')"
eq 'labwc_key xf86'   'XF86AudioMute'              "$(labwc_key XF86AudioMute)"
eq 'gtk_key xf86'     'XF86AudioMute'              "$(gtk_key XF86AudioMute)"
eq 'xf86 labwc rt'    'XF86AudioMute'              "$(from_labwc "$(labwc_key XF86AudioMute)")"
eq 'xf86 gtk rt'      'ctrl+XF86AudioMute'         "$(from_gtk "$(gtk_key ctrl+XF86AudioMute)")"
eq 'gtk plus'         'ctrl+shift++'               "$(from_gtk '<Control><Shift>plus')"
eq 'gtk minus'        'ctrl+-'                     "$(from_gtk '<Control>minus')"
eq 'gtk_key plus'     '<Control>plus'              "$(gtk_key 'ctrl++')"
eq 'gtk_key minus'    '<Control>minus'             "$(gtk_key 'ctrl+-')"
eq 'labwc_key plus'   'C-plus'                     "$(labwc_key 'ctrl++')"
eq 'labwc_key minus'  'C-minus'                    "$(labwc_key 'ctrl+-')"
for k in 'ctrl++' 'ctrl+-' 'alt+-' 'ctrl+shift++' '+' '-'; do
  eq "gtk rt ${k}"   "${k}" "$(from_gtk "$(gtk_key "${k}")")"
  eq "labwc rt ${k}" "${k}" "$(from_labwc "$(labwc_key "${k}")")"
done

[ "${FAIL}" -eq 0 ] && echo "keys-lib: all passed"
exit "${FAIL}"
