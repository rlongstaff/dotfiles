#!/usr/bin/env bash
# End-to-end: throwaway app instances, then parse capture.sh output with yq.
set -u
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
CAP="${SCRIPT_DIR}/scripts/keyboard/capture.sh"
. "${SCRIPT_DIR}/scripts/keyboard/keys-lib.sh"
FAIL=0
ok()  { echo "ok   $1"; }
bad() { echo "FAIL $1"; FAIL=1; }
T=$(mktemp -d)
# Every tmux server the tests start lives in a private directory under a per-run name, so two
# runs at once (or a live tmux) cannot collide.
export TMUX_TMPDIR="$T/tmx"; mkdir -p "$TMUX_TMPDIR"
SOCK="capt-$$"
# skip NAME: a test that cannot run here, reported like the others.
skip() { echo "skip $1"; }
VH="$T/vhome"; mkdir -p "$VH"
trap 'tmux -L "${SOCK}" kill-server 2>/dev/null; rm -rf "$T"' EXIT

# usage / unknown app
rc=0; "${CAP}" nosuchapp >/dev/null 2>&1 || rc=$?
[ "${rc}" -eq 2 ] && ok "bad app exits 2" || bad "bad app exits 2 (got ${rc})"
rc=0; "${CAP}" --bogus >/dev/null 2>&1 || rc=$?
[ "${rc}" -eq 2 ] && ok "bad option exits 2" || bad "bad option exits 2 (got ${rc})"

# tmux: user bindings captured, defaults not, alt+shift+tab is one binding
tmux -L "${SOCK}" -f /dev/null new-session -d -s x
tmux -L "${SOCK}" bind -n M-q kill-pane \; bind -n M-BTab select-pane -t :.- \; bind -n M-S-Tab select-pane -t :.-
tmux -L "${SOCK}" bind -n 'M-\' split-window -h -c '#{pane_current_path}' \; bind -n 'M-#' display-message 'a: b' \; bind -n M-% kill-pane
out=$(CAPTURE_TMUX_SOCKET="${SOCK}" "${CAP}" tmux 2>"$T/err")
printf '%s\n' "${out}" > "$T/out.yaml"
yq -e '.layers' "$T/out.yaml" >/dev/null 2>&1 && ok "output parses as yaml" || bad "output parses as yaml"
q() { yq -e "$1" "$T/out.yaml" >/dev/null 2>&1; }
q '.layers[] | select(.id=="tmux") | .bindings[] | select(.key=="alt+q")' \
  && ok "tmux alt+q captured" || bad "tmux alt+q captured"
n=$(yq '[.layers[].bindings[] | select(.key=="alt+shift+tab")] | length' "$T/out.yaml")
[ "${n}" = 1 ] && ok "alt+shift+tab once" || bad "alt+shift+tab once (got ${n})"
n=$(yq '[.layers[].bindings[] | select(.key=="alt+shift+tab") | .tmux] | length' "$T/out.yaml")
[ "${n}" = 1 ] && ok "alt+shift+tab one tmux field" || bad "alt+shift+tab one tmux field (got ${n})"
q '.layers[].bindings[] | select(.key=="ctrl+b")' \
  && bad "default prefix not leaked" || ok "default prefix not leaked"
q '.layers[].bindings[] | select(.key=="alt+\\")' && ok "alt+backslash captured" || bad "alt+backslash captured"
q '.layers[].bindings[] | select(.key=="alt+#")' && ok "alt+# captured" || bad "alt+# captured"
q '.layers[].bindings[] | select(.key=="alt+%")' && ok "alt+% captured" || bad "alt+% captured"
[ "$(yq '.layers[].bindings[] | select(.key=="alt+#") | .tmux.cmd' "$T/out.yaml")" = 'display-message "a: b"' ] \
  && ok "cmd with quotes and colon survives" || bad "cmd with quotes and colon survives"
# every captured key is canonical
badkeys=0
for k in $(yq '.layers[].bindings[].key' "$T/out.yaml" | tr ' ' '_'); do
  validate "$k" >/dev/null || badkeys=1
done
[ "${badkeys}" -eq 0 ] && ok "all keys validate" || bad "all keys validate"
# --all keeps defaults
all=$(CAPTURE_TMUX_SOCKET="${SOCK}" "${CAP}" --all tmux 2>/dev/null)
printf '%s\n' "${all}" | yq -e '.layers[].bindings[] | select(.key=="ctrl+b")' >/dev/null 2>&1 \
  && ok "--all keeps default prefix" || bad "--all keeps default prefix"
tmux -L "${SOCK}" kill-server

# pass: vim recovered from the repo's own config
tmux -L "${SOCK}" -f "${SCRIPT_DIR}/.tmux/keys.conf" new-session -d -s y
CAPTURE_TMUX_SOCKET="${SOCK}" "${CAP}" tmux > "$T/repo.yaml" 2>/dev/null
h() { yq -r ".layers[].bindings[] | select(.key==\"alt+h\") | .tmux.$1" "$T/repo.yaml"; }
[ "$(h cmd)" = "select-pane -L" ] && ok "alt+h cmd" || bad "alt+h cmd (got $(h cmd))"
[ "$(h pass)" = "vim" ] && ok "alt+h pass vim" || bad "alt+h pass vim (got $(h pass))"
p=$(yq -r '.layers[].bindings[] | select(.key=="pageup") | .tmux.pass' "$T/repo.yaml")
[ "${p}" = "pager" ] && ok "pageup pass pager" || bad "pageup pass pager (got ${p})"
tmux -L "${SOCK}" kill-server

# absent: no server -> INFO, exit 0, empty layers
rc=0; out=$(CAPTURE_TMUX_SOCKET=nonesuch "${CAP}" tmux 2>"$T/err") || rc=$?
[ "${rc}" -eq 0 ] && grep -q '^capture: INFO tmux: not detected' "$T/err" \
  && ok "tmux absent INFO" || bad "tmux absent INFO"
printf '%s\n' "${out}" | yq -e '.layers' >/dev/null 2>&1 && ok "absent output still yaml" || bad "absent output still yaml"

# vim: a user map is captured, collapsed across modes; cmd recovered from the per-mode wrapper
cat > "$T/vimrc" <<'EOF'
nnoremap <C-Up> <C-u>
inoremap <C-Up> <C-u>
vnoremap <C-Up> <C-u>
nnoremap <silent> <M-f> :Commentary<CR>
inoremap <silent> <M-f> <C-o>:Commentary<CR>
vnoremap <silent> <M-f> <Esc>:Commentary<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <leader>abcdefgh :echo "a  b"<CR>
nnoremap <F6> @q
nnoremap <C-a> :Foo<CR>
inoremap <C-a> <C-o>:Foo<CR>
nnoremap <M-H> <C-w>h
EOF
rc=0; out=$(HOME="$VH" CAPTURE_VIM_ARGS="-u $T/vimrc" "${CAP}" vim 2>"$T/err") || rc=$?
printf '%s\n' "${out}" > "$T/vim.yaml"
vq() { yq -e "$1" "$T/vim.yaml" >/dev/null 2>&1; }
{ [ "${rc}" -eq 0 ] && vq '.layers[] | select(.id=="vim")'; } && ok "vim layer emitted" || bad "vim layer emitted (rc ${rc})"
vq '.layers[].bindings[] | select(.key=="ctrl+up") | .vim.modes | contains(["n","i","v"])' \
  && ok "vim modes collapse" || bad "vim modes collapse"
[ "$(yq '[.layers[].bindings[] | select(.key=="ctrl+up")] | length' "$T/vim.yaml")" = 1 ] \
  && ok "vim ctrl+up one binding" || bad "vim ctrl+up one binding"
[ "$(yq '.layers[].bindings[] | select(.key=="ctrl+up") | .vim.rhs' "$T/vim.yaml")" = "<C-u>" ] \
  && ok "vim rhs kept" || bad "vim rhs kept"
vq '.layers[].bindings[] | select(.key=="alt+f") | .vim.modes | contains(["n","i","v"])' \
  && ok "vim alt+f modes" || bad "vim alt+f modes"
[ "$(yq '.layers[].bindings[] | select(.key=="alt+f") | .vim.cmd' "$T/vim.yaml")" = "Commentary" ] \
  && ok "vim alt+f cmd unwrapped" || bad "vim alt+f cmd unwrapped"
[ "$(yq '.layers[].bindings[] | select(.key=="ctrl+t") | .vim.cmd' "$T/vim.yaml")" = "NERDTreeToggle" ] \
  && ok "vim ctrl+t cmd" || bad "vim ctrl+t cmd"
[ "$(yq '.layers[].bindings[] | select(.key=="f6") | .vim.rhs' "$T/vim.yaml")" = "@q" ] \
  && ok "vim rhs with leading @ (flag column)" || bad "vim rhs with leading @ (flag column)"
[ "$(yq '.layers[].bindings[] | select(.key=="ctrl+a") | .vim.cmd' "$T/vim.yaml")" = "Foo" ] \
  && vq '.layers[].bindings[] | select(.key=="ctrl+a") | .vim.modes | contains(["n","i"])' \
  && ok "vim <C-A> is ctrl+a, uppercase wrapper unwrapped" || bad "vim <C-A> is ctrl+a, uppercase wrapper unwrapped"
vq '.layers[].bindings[] | select(.key=="alt+shift+h")' && ok "vim <M-H> stays alt+shift+h" || bad "vim <M-H> stays alt+shift+h"
vq '.layers[].bindings[] | select(.key=="enter")' && bad "vim default map not leaked" || ok "vim default map not leaked"
grep -q '^ *# UNMAPPED vim: <leader>abcdefgh' "$T/vim.yaml" && ok "vim unmappable lhs reported" || bad "vim unmappable lhs reported"
# repo's own vimrc: plugin maps (gcc, <Plug>...) dropped by default
out=$(HOME="$VH" CAPTURE_VIM_ARGS="-u ${SCRIPT_DIR}/.vimrc" "${CAP}" vim 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="ctrl+t")' >/dev/null 2>&1 \
  && ok "vim repo ctrl+t" || bad "vim repo ctrl+t"
printf '%s\n' "${out}" | grep -q 'gcc\|Plug' && bad "vim repo plugin maps dropped" || ok "vim repo plugin maps dropped"
# vim with no user maps: exit 0, still yaml
rc=0; out=$(HOME="$VH" CAPTURE_VIM_ARGS="-u NONE" "${CAP}" vim 2>/dev/null) || rc=$?
{ [ "${rc}" -eq 0 ] && printf '%s\n' "${out}" | yq -e '.layers' >/dev/null 2>&1; } \
  && ok "vim no maps ok" || bad "vim no maps ok"

# vim default invocation (no CAPTURE_VIM_ARGS): the user's vimrc is found from HOME
mkdir -p "$T/home"; printf 'nnoremap <C-Up> <C-u>\nnnoremap <F7> :Foo<CR>\n' > "$T/home/.vimrc"
rc=0; out=$(HOME="$T/home" "${CAP}" vim 2>/dev/null) || rc=$?
{ [ "${rc}" -eq 0 ] && printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="f7") | .vim.cmd == "Foo"' >/dev/null 2>&1; } \
  && ok "vim default path finds ~/.vimrc" || bad "vim default path finds ~/.vimrc (rc ${rc})"
mkdir -p "$T/home2"
rc=0; out=$(HOME="$T/home2" XDG_CONFIG_HOME="$T/home2/.config" "${CAP}" vim 2>"$T/err") || rc=$?
{ [ "${rc}" -eq 0 ] && grep -q '^capture: INFO vim: not detected (no vimrc found)' "$T/err"; } \
  && ok "vim no vimrc INFO" || bad "vim no vimrc INFO"
# a user vimrc living in a directory named pack / vendor / bundle is still the user's
for d in pack vendor bundle; do
  mkdir -p "$T/x/$d/r"; printf 'nnoremap <F8> :Bar<CR>\n' > "$T/x/$d/r/vimrc"
  out=$(HOME="$VH" CAPTURE_VIM_ARGS="-u $T/x/$d/r/vimrc" "${CAP}" vim 2>/dev/null)
  printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="f8")' >/dev/null 2>&1 \
    && ok "vim vimrc under /$d/ kept" || bad "vim vimrc under /$d/ kept"
done
# plugin script maps are dropped (repo vendor/vim-commentary), repo keys.vim kept
out=$(HOME="$VH" CAPTURE_VIM_ARGS="-u ${SCRIPT_DIR}/.vimrc" "${CAP}" vim 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="alt+f")' >/dev/null 2>&1 \
  && ok "vim repo keys.vim alt+f kept" || bad "vim repo keys.vim alt+f kept"
# only runtime/plugin maps present: INFO, exit 0
rc=0; out=$(HOME="$VH" CAPTURE_VIM_ARGS="-u NONE -N" "${CAP}" vim 2>"$T/err") || rc=$?
{ [ "${rc}" -eq 0 ] && grep -q '^capture: INFO vim: no user-defined mappings found' "$T/err"; } \
  && ok "vim no user maps INFO" || bad "vim no user maps INFO"

# kitty: user map captured, default dropped, no_op override kept
mkdir -p "$T/kitty"
printf 'map alt+q close_window\nmap ctrl+shift+c no_op\nmap f5 launch --type=os-window ls\nmap ctrl+shift+page_up scroll_page_up\n' > "$T/kitty/kitty.conf"
rc=0; out=$(KITTY_CONFIG_DIRECTORY="$T/kitty" "${CAP}" kitty 2>"$T/err") || rc=$?
printf '%s\n' "${out}" > "$T/kitty.yaml"
kq() { yq -e "$1" "$T/kitty.yaml" >/dev/null 2>&1; }
{ [ "${rc}" -eq 0 ] && kq '.layers[] | select(.id=="terminal")'; } && ok "kitty terminal layer" || bad "kitty terminal layer (rc ${rc})"
kq '.layers[].bindings[] | select(.key=="alt+q") | .kitty == "close_window"' && ok "kitty alt+q" || bad "kitty alt+q"
kq '.layers[].bindings[] | select(.key=="f5") | .kitty == "launch --type=os-window ls"' \
  && ok "kitty action with args" || bad "kitty action with args"
kq '.layers[].bindings[] | select(.key=="ctrl+shift+c") | .kitty == "no_op"' && ok "kitty no_op override" || bad "kitty no_op override"
kq '.layers[].bindings[] | select(.key=="ctrl+shift+pageup")' && bad "kitty default not leaked" || ok "kitty default not leaked"
out=$(KITTY_CONFIG_DIRECTORY="$T/kitty" "${CAP}" --all kitty 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="ctrl+shift+pageup")' >/dev/null 2>&1 \
  && ok "kitty --all keeps defaults" || bad "kitty --all keeps defaults"

# shell: bash and zsh read from throwaway interactive shells (HOME points at a temp dir, so
# the reader's default path is what runs).  Every throwaway shell must keep tmux out of it.
tmux_socks() { find "$TMUX_TMPDIR" -type s 2>/dev/null | wc -l | tr -d ' '; }
mkdir -p "$T/sh1"
printf '%s\n' "bind '\"\\e[1;5D\": vi-bword'" "bind '\"\\e[1;2A\": history-search-backward'" \
  "bind '\"\\C-q\": kill-line'" > "$T/sh1/.bashrc"
printf '%s\n' "bindkey '^[[1;5D' backward-word" "bindkey '^[[1;2A' history-search-backward" \
  "bindkey '^A' kill-line" > "$T/sh1/.zshrc"
rc=0; out=$(HOME="$T/sh1" INPUTRC=/dev/null "${CAP}" bash zsh 2>"$T/err") || rc=$?
printf '%s\n' "${out}" > "$T/sh.yaml"
sq() { yq -e "$1" "$T/sh.yaml" >/dev/null 2>&1; }
{ [ "${rc}" -eq 0 ] && sq '.layers[] | select(.id=="shell")'; } && ok "shell layer emitted" || bad "shell layer emitted (rc ${rc})"
sq '.layers[].bindings[] | select(.key=="ctrl+left" and .bash == "vi-bword" and .zsh == "backward-word")' \
  && ok "ctrl+left from both shells merged" || bad "ctrl+left from both shells merged"
[ "$(yq '[.layers[].bindings[] | select(.key=="ctrl+left")] | length' "$T/sh.yaml")" = 1 ] \
  && ok "ctrl+left one binding" || bad "ctrl+left one binding"
sq '.layers[].bindings[] | select(.key=="ctrl+a") | .zsh == "kill-line"' && ok "zsh ^A is ctrl+a" || bad "zsh ^A is ctrl+a"
sq '.layers[].bindings[] | select(.key=="ctrl+e")' && bad "shell default not leaked" || ok "shell default not leaked"
grep -q '^ *# UNMAPPED bash: \\e\[1;2A history-search-backward' "$T/sh.yaml" \
  && ok "bash unmapped sequence reported" || bad "bash unmapped sequence reported"
grep -q '^ *# UNMAPPED zsh: \\e\[1;2A history-search-backward' "$T/sh.yaml" \
  && ok "zsh unmapped sequence normalised and reported" || bad "zsh unmapped sequence normalised and reported"
grep -q 'C-q' "$T/sh.yaml" && ok "bash unmapped control key reported" || bad "bash unmapped control key reported"
# INPUTRC alone (no rc file) is enough to bind
mkdir -p "$T/sh2"; printf '"\\e[3;5~": backward-kill-word\n' > "$T/inputrc"
out=$(HOME="$T/sh2" INPUTRC="$T/inputrc" "${CAP}" bash 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="ctrl+delete") | .bash == "backward-kill-word"' >/dev/null 2>&1 \
  && ok "bash INPUTRC binding captured" || bad "bash INPUTRC binding captured"
# the repo's own shell config: --all shows both fields on the keys keys.sh binds
mkdir -p "$T/sh3"
ln -s "${SCRIPT_DIR}/.shell" "$T/sh3/.shell"; ln -s .shell/.bashrc "$T/sh3/.bashrc"
ln -s .shell/.zshrc "$T/sh3/.zshrc"; ln -s "${SCRIPT_DIR}" "$T/sh3/.dotfiles"
before=$(tmux_socks)
rc=0; out=$(HOME="$T/sh3" "${CAP}" --all bash zsh 2>/dev/null) || rc=$?
printf '%s\n' "${out}" > "$T/sh3.yaml"
for k in home end delete ctrl+left ctrl+right; do
  yq -e ".layers[].bindings[] | select(.key==\"${k}\" and .bash != null and .zsh != null)" "$T/sh3.yaml" >/dev/null 2>&1 \
    && ok "--all ${k} has bash and zsh" || bad "--all ${k} has bash and zsh"
done
[ "$(yq -r '.layers[].bindings[] | select(.key=="ctrl+right") | .bash' "$T/sh3.yaml")" = "vi-fword" ] \
  && ok "bash alias names collapse to one" || bad "bash alias names collapse to one"
[ "$(yq '[.layers[].bindings[] | select(.key=="ctrl+right")] | length' "$T/sh3.yaml")" = 1 ] \
  && ok "ctrl+right one binding" || bad "ctrl+right one binding"
[ "$(tmux_socks)" = "${before}" ] && ok "readers start no tmux server" || bad "readers start no tmux server"
# user-only on the repo config: repo bindings are the user's, so they appear without --all
out=$(HOME="$T/sh3" "${CAP}" bash zsh 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="ctrl+left")' >/dev/null 2>&1 \
  && ok "user-only keeps repo bindings" || bad "user-only keeps repo bindings"
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="ctrl+k")' >/dev/null 2>&1 \
  && bad "user-only drops shell defaults" || ok "user-only drops shell defaults"
# nothing user-defined: INFO, exit 0, still yaml
mkdir -p "$T/sh4"; : > "$T/sh4/.bashrc"; : > "$T/sh4/.zshrc"
rc=0; out=$(HOME="$T/sh4" INPUTRC=/dev/null "${CAP}" bash zsh 2>"$T/err") || rc=$?
{ [ "${rc}" -eq 0 ] && grep -q '^capture: INFO bash: no user-defined bindings found' "$T/err" \
  && grep -q '^capture: INFO zsh: no user-defined bindings found' "$T/err"; } \
  && ok "shell no user bindings INFO" || bad "shell no user bindings INFO (rc ${rc}: $(cat "$T/err"))"
printf '%s\n' "${out}" | yq -e '.layers' >/dev/null 2>&1 && ok "empty shell output still yaml" || bad "empty shell output still yaml"
# shell missing / dump failing: one INFO each, exit 0
mkdir -p "$T/bin"
for tool in mktemp rm find sed awk tr cat grep head tail cp yq which dirname wc cut sort uniq mkdir; do
  p=$(command -v "${tool}") && ln -sf "${p}" "$T/bin/${tool}"
done
rc=0; PATH="$T/bin" "$(command -v bash)" "${CAP}" bash zsh >/dev/null 2>"$T/err" || rc=$?
{ [ "${rc}" -eq 0 ] && [ "$(grep -c '^capture: INFO bash: not detected' "$T/err")" = 1 ] \
  && [ "$(grep -c '^capture: INFO zsh: not detected' "$T/err")" = 1 ]; } \
  && ok "shell missing INFO once each" || bad "shell missing INFO once each (rc ${rc}: $(cat "$T/err"))"
printf '#!/bin/sh\nexit 1\n' > "$T/bin/bash"; cp "$T/bin/bash" "$T/bin/zsh"; chmod +x "$T/bin/bash" "$T/bin/zsh"
rc=0; PATH="$T/bin" "$(command -v bash)" "${CAP}" bash zsh >/dev/null 2>"$T/err" || rc=$?
{ [ "${rc}" -eq 0 ] && [ "$(grep -c '^capture: INFO bash: not detected' "$T/err")" = 1 ] \
  && [ "$(grep -c '^capture: INFO zsh: not detected' "$T/err")" = 1 ]; } \
  && ok "shell dump failing INFO once each" || bad "shell dump failing INFO once each (rc ${rc}: $(cat "$T/err"))"

# labwc: keybinds outside the GENERATED block are the user's; multi-line and one-line shapes,
# several actions, XML entities
cat > "$T/rc.xml" <<'EOF'
<labwc_config><keyboard>
<!-- BEGIN GENERATED from keys.yaml by render.sh; edit the yaml -->
    <keybind key="W-t">
      <action name="Execute" command="kitty"/>
    </keybind>
<!-- END GENERATED -->
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="W-S-Tab">
      <action name="PreviousWindow" workspace="current" output="all"/>
    </keybind>
    <keybind key="W-e"><action name="Execute" command="a &amp;&amp; b &lt;c&gt; &quot;d&quot;"/></keybind>
    <keybind key="C-A-x">
      <action name="Close"/>
      <action name="Execute" command="foo"/>
    </keybind>
    <keybind key="W-Bogus-Key"><action name="Close"/></keybind>
    <!-- <keybind key="W-z"><action name="Close"/></keybind> -->
</keyboard></labwc_config>
EOF
rc=0; out=$(CAPTURE_LABWC_RC="$T/rc.xml" "${CAP}" labwc 2>"$T/err") || rc=$?
printf '%s\n' "${out}" > "$T/lw.yaml"
lq() { yq -e "$1" "$T/lw.yaml" >/dev/null 2>&1; }
{ [ "${rc}" -eq 0 ] && lq '.layers[] | select(.id=="compositor")'; } && ok "labwc compositor layer" || bad "labwc compositor layer (rc ${rc})"
lq '.layers[].bindings[] | select(.key=="alt+f4") | .labwc.action == "Close"' && ok "labwc user keybind" || bad "labwc user keybind"
lq '.layers[].bindings[] | select(.key=="super+t")' && bad "labwc generated block skipped" || ok "labwc generated block skipped"
lq '.layers[].bindings[] | select(.key=="shift+super+tab" and .labwc.action == "PreviousWindow" and .labwc.workspace == "current" and .labwc.output == "all")' \
  && ok "labwc multi-line keybind with attributes" || bad "labwc multi-line keybind with attributes"
lq '.layers[].bindings[] | select(.key=="super+e") | .labwc.command == "a && b <c> \"d\""' \
  && ok "labwc XML entities decoded" || bad "labwc XML entities decoded"
lq '.layers[].bindings[] | select(.key=="ctrl+alt+x") | .labwc.action == "Close"' && ok "labwc first action kept" || bad "labwc first action kept"
grep -q '^ *# UNMAPPED labwc: C-A-x extra action Execute' "$T/lw.yaml" && ok "labwc extra action reported" || bad "labwc extra action reported"
grep -q '^ *# UNMAPPED labwc: W-Bogus-Key' "$T/lw.yaml" && ok "labwc unmappable key reported" || bad "labwc unmappable key reported"
lq '.layers[].bindings[] | select(.key=="super+z")' && bad "labwc commented keybind ignored" || ok "labwc commented keybind ignored"
out=$(CAPTURE_LABWC_RC="$T/rc.xml" "${CAP}" --all labwc 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="super+t") | .labwc.command == "kitty"' >/dev/null 2>&1 \
  && ok "labwc --all keeps generated block" || bad "labwc --all keeps generated block"
cat > "$T/rc-gen.xml" <<'EOF'
<labwc_config><keyboard>
<!-- BEGIN GENERATED from keys.yaml by render.sh; edit the yaml -->
    <keybind key="W-t"><action name="Execute" command="kitty"/></keybind>
<!-- END GENERATED -->
</keyboard></labwc_config>
EOF
rc=0; out=$(CAPTURE_LABWC_RC="$T/rc-gen.xml" "${CAP}" labwc 2>"$T/err") || rc=$?
{ [ "${rc}" -eq 0 ] && grep -q '^capture: INFO labwc: no user-defined bindings found' "$T/err"; } \
  && ok "labwc only generated: no-user INFO" || bad "labwc only generated: no-user INFO"
rc=0; out=$(CAPTURE_LABWC_RC="$T/none.xml" "${CAP}" labwc 2>"$T/err") || rc=$?
{ [ "${rc}" -eq 0 ] && [ "$(grep -c '^capture: INFO labwc: not detected' "$T/err")" = 1 ]; } \
  && ok "labwc absent INFO" || bad "labwc absent INFO"
# default path: rc.xml found from XDG_CONFIG_HOME / HOME
mkdir -p "$T/lwhome/.config/labwc"; cp "$T/rc.xml" "$T/lwhome/.config/labwc/rc.xml"
out=$(HOME="$T/lwhome" XDG_CONFIG_HOME="" "${CAP}" labwc 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="alt+f4")' >/dev/null 2>&1 \
  && ok "labwc default path finds ~/.config/labwc/rc.xml" || bad "labwc default path finds ~/.config/labwc/rc.xml"
rc=0; out=$(HOME="$T/nohome" XDG_CONFIG_HOME="" "${CAP}" labwc 2>"$T/err") || rc=$?
{ [ "${rc}" -eq 0 ] && grep -q '^capture: INFO labwc: not detected' "$T/err"; } \
  && ok "labwc default path absent INFO" || bad "labwc default path absent INFO"
# the repo's own rc.xml (render.sh output): --all sees the generated bindings
out=$(CAPTURE_LABWC_RC="${SCRIPT_DIR}/.config/labwc/rc.xml" "${CAP}" --all labwc 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="super+tab") | .labwc.action == "NextWindow"' >/dev/null 2>&1 \
  && ok "labwc repo rc.xml super+tab" || bad "labwc repo rc.xml super+tab"
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="super+l") | .labwc.command == "swaylock -f -c 000000"' >/dev/null 2>&1 \
  && ok "labwc repo rc.xml command" || bad "labwc repo rc.xml command"

# labwc: XF86 keysyms, extra keybind attributes and child-element actions are not dropped silently
cat > "$T/rc-x.xml" <<'EOF'
<labwc_config><keyboard>
    <keybind key="XF86AudioMute"><action name="Execute" command="pactl set-sink-mute @DEFAULT_SINK@ toggle"/></keybind>
    <keybind key="C-XF86AudioRaiseVolume"><action name="Close"/></keybind>
    <keybind key="W-r" onRelease="yes" layoutDependent="yes"><action name="Close"/></keybind>
    <keybind key="W-c"><action name="Execute"><command>foo</command></action></keybind>
    <keybind key="W-d"><action name="Close"></action></keybind>
</keyboard></labwc_config>
EOF
CAPTURE_LABWC_RC="$T/rc-x.xml" "${CAP}" labwc > "$T/lx.yaml" 2>/dev/null
yq -e '.layers[].bindings[] | select(.key=="XF86AudioMute")' "$T/lx.yaml" >/dev/null 2>&1 \
  && ok "labwc XF86 key captured" || bad "labwc XF86 key captured"
yq -e '.layers[].bindings[] | select(.key=="ctrl+XF86AudioRaiseVolume")' "$T/lx.yaml" >/dev/null 2>&1 \
  && ok "labwc ctrl+XF86 key captured" || bad "labwc ctrl+XF86 key captured"
grep -q '^ *# UNMAPPED labwc: W-r attribute onRelease' "$T/lx.yaml" && grep -q 'W-r attribute layoutDependent' "$T/lx.yaml" \
  && ok "labwc extra keybind attributes reported" || bad "labwc extra keybind attributes reported"
grep -q '^ *# UNMAPPED labwc: W-c child elements of action Execute' "$T/lx.yaml" \
  && ok "labwc child-element action reported" || bad "labwc child-element action reported"
grep -q 'W-d child' "$T/lx.yaml" && bad "labwc empty action body not reported" || ok "labwc empty action body not reported"
# the repo's own rc.xml: every labwc key in keys.yaml's compositor layer is captured
yq -r '.layers[] | select(.id=="compositor") | .bindings[] | select(.labwc != null) | .key' "${SCRIPT_DIR}/keys.yaml" | sort > "$T/want.keys"
CAPTURE_LABWC_RC="${SCRIPT_DIR}/.config/labwc/rc.xml" "${CAP}" --all labwc 2>"$T/err" > "$T/lr.yaml"
yq -r '.layers[].bindings[] | select(.labwc != null) | .key' "$T/lr.yaml" | sort > "$T/got.keys"
{ [ -s "$T/want.keys" ] && diff "$T/want.keys" "$T/got.keys" >/dev/null && ! grep -q UNMAPPED "$T/lr.yaml"; } \
  && ok "repo rc.xml captures every labwc key in keys.yaml ($(wc -l < "$T/want.keys" | tr -d ' '))" \
  || bad "repo rc.xml captures every labwc key in keys.yaml"
# gnome: XF86 and plus/minus accelerators map
printf "%s\n" "org.gnome.settings-daemon.plugins.media-keys screen-brightness-up ['XF86MonBrightnessUp']" > "$T/gs-xf"
: > "$T/gs-none"
out=$(CAPTURE_GNOME_LIVE="$T/gs-xf" CAPTURE_GNOME_DEFAULT="$T/gs-none" "${CAP}" gnome 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="XF86MonBrightnessUp")' >/dev/null 2>&1 \
  && ok "gnome XF86 key captured" || bad "gnome XF86 key captured"
printf '%s\n' "${out}" | grep -q UNMAPPED && bad "gnome XF86 not UNMAPPED" || ok "gnome XF86 not UNMAPPED"
printf "[/]\nzoom-in='<Control>plus'\nzoom-out='<Control>minus'\n" > "$T/gt-zoom"
out=$(CAPTURE_GT_DUMP="$T/gt-zoom" CAPTURE_GT_DEFAULT="$T/gs-none" "${CAP}" gnome-terminal 2>/dev/null)
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="ctrl++" and .["gnome-terminal"]=="zoom-in")' >/dev/null 2>&1 \
  && ok "gnome-terminal ctrl+plus captured" || bad "gnome-terminal ctrl+plus captured"
printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="ctrl+-")' >/dev/null 2>&1 \
  && ok "gnome-terminal ctrl+minus captured" || bad "gnome-terminal ctrl+minus captured"

# gnome: fixture dumps (live and schema defaults) stand in for gsettings
cat > "$T/gs-def" <<'EOF'
org.gnome.desktop.wm.keybindings switch-applications ['<Super>Tab', '<Alt>Tab']
org.gnome.desktop.wm.keybindings close ['<Super>q']
org.gnome.desktop.wm.keybindings always-on-top @as []
org.gnome.shell.keybindings toggle-message-tray ['<Super>v']
org.gnome.shell.keybindings toggle-application-view ['<Super>a']
org.gnome.shell.keybindings focus-active-notification ['<Super>n']
org.gnome.shell.keybindings other-string 'hello'
EOF
cat > "$T/gs-live" <<'EOF'
org.gnome.desktop.wm.keybindings switch-applications ['<Super>Tab', '<Primary><Shift>Tab']
org.gnome.desktop.wm.keybindings close ['<Super>q']
org.gnome.desktop.wm.keybindings always-on-top @as []
org.gnome.shell.keybindings toggle-message-tray ['<Super>v']
org.gnome.shell.keybindings toggle-application-view @as []
org.gnome.shell.keybindings focus-active-notification []
org.gnome.shell.keybindings other-string 'bye'
EOF
rc=0; out=$(CAPTURE_GNOME_LIVE="$T/gs-live" CAPTURE_GNOME_DEFAULT="$T/gs-def" "${CAP}" gnome 2>"$T/err") || rc=$?
printf '%s\n' "${out}" > "$T/gn.yaml"
gq() { yq -e "$1" "$T/gn.yaml" >/dev/null 2>&1; }
{ [ "${rc}" -eq 0 ] && gq '.layers[] | select(.id=="compositor")'; } && ok "gnome compositor layer" || bad "gnome compositor layer (rc ${rc})"
gq '.layers[].bindings[] | select(.key=="super+tab" and .gnome.schema == "org.gnome.desktop.wm.keybindings" and .gnome.name == "switch-applications")' \
  && ok "gnome user key captured" || bad "gnome user key captured"
gq '.layers[].bindings[] | select(.key=="ctrl+shift+tab") | .gnome.name == "switch-applications"' \
  && ok "gnome one record per accelerator" || bad "gnome one record per accelerator"
gq '.layers[].bindings[] | select(.key=="super+q")' && bad "gnome default not leaked" || ok "gnome default not leaked"
gq '.layers[].bindings[] | select(.key=="alt+tab")' && bad "gnome default accelerator not leaked" || ok "gnome default accelerator not leaked"
grep -q '^ *# UNMAPPED gnome: org.gnome.shell.keybindings toggle-application-view (unbound)' "$T/gn.yaml" \
  && ok "gnome emptied binding reported" || bad "gnome emptied binding reported"
grep -q 'focus-active-notification (unbound)' "$T/gn.yaml" && ok "gnome [] reported" || bad "gnome [] reported"
grep -q 'always-on-top' "$T/gn.yaml" && bad "gnome unchanged empty not reported" || ok "gnome unchanged empty not reported"
grep -q 'other-string' "$T/gn.yaml" && bad "gnome non-key value ignored" || ok "gnome non-key value ignored"
out=$(CAPTURE_GNOME_LIVE="$T/gs-live" CAPTURE_GNOME_DEFAULT="$T/gs-def" "${CAP}" --all gnome 2>/dev/null)
printf '%s\n' "${out}" > "$T/gn.yaml"
gq '.layers[].bindings[] | select(.key=="super+q") | .gnome.name == "close"' && ok "gnome --all keeps defaults" || bad "gnome --all keeps defaults"
grep -q '(unbound)' "$T/gn.yaml" && bad "gnome --all no unbound comments" || ok "gnome --all no unbound comments"
cp "$T/gs-def" "$T/gs-same"
rc=0; out=$(CAPTURE_GNOME_LIVE="$T/gs-same" CAPTURE_GNOME_DEFAULT="$T/gs-def" "${CAP}" gnome 2>"$T/err") || rc=$?
{ [ "${rc}" -eq 0 ] && grep -q '^capture: INFO gnome: no user-defined bindings found' "$T/err"; } \
  && ok "gnome no user bindings INFO" || bad "gnome no user bindings INFO"

# gnome-terminal: dconf dump (user-set only) against schema defaults
cat > "$T/gt-def" <<'EOF'
org.gnome.Terminal.Legacy.Keybindings copy '<Control><Shift>c'
org.gnome.Terminal.Legacy.Keybindings paste '<Control><Shift>v'
org.gnome.Terminal.Legacy.Keybindings find '<Control><Shift>f'
org.gnome.Terminal.Legacy.Keybindings full-screen 'F11'
org.gnome.Terminal.Legacy.Keybindings copy-html 'disabled'
EOF
cat > "$T/gt-dump" <<'EOF'
[/]
copy='<Super>c'
paste='<Control><Shift>v'
full-screen='disabled'
EOF
rc=0; out=$(CAPTURE_GT_DUMP="$T/gt-dump" CAPTURE_GT_DEFAULT="$T/gt-def" "${CAP}" gnome-terminal 2>"$T/err") || rc=$?
printf '%s\n' "${out}" > "$T/gt.yaml"
tq() { yq -e "$1" "$T/gt.yaml" >/dev/null 2>&1; }
{ [ "${rc}" -eq 0 ] && tq '.layers[] | select(.id=="terminal")'; } && ok "gnome-terminal terminal layer" || bad "gnome-terminal terminal layer (rc ${rc})"
tq '.layers[].bindings[] | select(.key=="super+c") | .["gnome-terminal"] == "copy"' && ok "gnome-terminal user key" || bad "gnome-terminal user key"
tq '.layers[].bindings[] | select(.key=="ctrl+shift+v")' && bad "gnome-terminal value equal to default dropped" || ok "gnome-terminal value equal to default dropped"
grep -q '^ *# UNMAPPED gnome-terminal: org.gnome.Terminal.Legacy.Keybindings full-screen (unbound)' "$T/gt.yaml" \
  && ok "gnome-terminal disabled reported" || bad "gnome-terminal disabled reported"
out=$(CAPTURE_GT_DUMP="$T/gt-dump" CAPTURE_GT_DEFAULT="$T/gt-def" "${CAP}" --all gnome-terminal 2>/dev/null)
printf '%s\n' "${out}" > "$T/gt.yaml"
tq '.layers[].bindings[] | select(.key=="ctrl+shift+f") | .["gnome-terminal"] == "find"' && ok "gnome-terminal --all keeps defaults" || bad "gnome-terminal --all keeps defaults"
tq '.layers[].bindings[] | select(.key=="ctrl+shift+c")' && bad "gnome-terminal --all user value replaces default" || ok "gnome-terminal --all user value replaces default"
tq '.layers[].bindings[] | select(.key=="super+c")' && ok "gnome-terminal --all has user value" || bad "gnome-terminal --all has user value"
printf '[/]\n' > "$T/gt-empty"
rc=0; out=$(CAPTURE_GT_DUMP="$T/gt-empty" CAPTURE_GT_DEFAULT="$T/gt-def" "${CAP}" gnome-terminal 2>"$T/err") || rc=$?
{ [ "${rc}" -eq 0 ] && grep -q '^capture: INFO gnome-terminal: no user-defined bindings found' "$T/err"; } \
  && ok "gnome-terminal no user bindings INFO" || bad "gnome-terminal no user bindings INFO"

# gnome / gnome-terminal tools missing: one INFO each, exit 0
mkdir -p "$T/bin2"
for tool in mktemp rm find sed awk tr cat grep head tail cp yq which dirname wc cut sort uniq mkdir; do
  p=$(command -v "${tool}") && ln -sf "${p}" "$T/bin2/${tool}"
done
rc=0; PATH="$T/bin2" "$(command -v bash)" "${CAP}" gnome gnome-terminal >/dev/null 2>"$T/err" || rc=$?
{ [ "${rc}" -eq 0 ] && [ "$(grep -c '^capture: INFO gnome: not detected' "$T/err")" = 1 ] \
  && [ "$(grep -c '^capture: INFO gnome-terminal: not detected' "$T/err")" = 1 ]; } \
  && ok "gnome tools missing INFO once each" || bad "gnome tools missing INFO once each (rc ${rc}: $(cat "$T/err"))"

# the real default invocations on this machine: exit 0 and valid yaml, with and without --all
dc_before=$(dconf dump / 2>/dev/null | md5sum)
for app in labwc gnome gnome-terminal; do
  for fl in "" --all; do
    rc=0; out=$("${CAP}" ${fl} "${app}" 2>"$T/err") || rc=$?
    { [ "${rc}" -eq 0 ] && printf '%s\n' "${out}" | yq -e '.layers' >/dev/null 2>&1; } \
      && ok "real ${app} ${fl:-default} exits 0, valid yaml" || bad "real ${app} ${fl:-default} exits 0, valid yaml (rc ${rc}: $(head -c 200 "$T/err"))"
  done
done
[ "$(dconf dump / 2>/dev/null | md5sum)" = "${dc_before}" ] && ok "readers leave dconf untouched" || bad "readers leave dconf untouched"

# iterm2: the JSON a `plutil -convert json` would give (macOS only), via CAPTURE_ITERM2_JSON
cat > "$T/iterm.json" <<'EOF'
{"GlobalKeyMap": {"0x74-0x100000-0x11": {"Action": 12, "Text": ""},
                  "0xf70f-0x0-0x6f": {"Action": 10, "Text": "[24~"}},
 "New Bookmarks": [
   {"Name": "Default", "Keyboard Map": {"0xf702-0x280000-0x7b": {"Action": 11, "Text": "0x1b 0x62"},
                                        "0x74-0x100000-0x11": {"Action": 13, "Text": ""}}},
   {"Name": "Other", "Keyboard Map": {"0xf702-0x280000-0x7b": {"Action": 11, "Text": "0x1b 0x62"},
                                       "0xf710-0x0-0x0": {"Action": 99, "Text": "x\ny"},
                                       "0x61-0x100000-0x0": {"Action": 12, "Text": "a very long text that goes on and on and on and on"}}},
   {"Name": "NoMap"}, "junk", null]}
EOF
rc=0; out=$(CAPTURE_ITERM2_JSON="$T/iterm.json" "${CAP}" iterm2 2>"$T/err") || rc=$?
printf '%s\n' "${out}" > "$T/it.yaml"
iq() { yq -e "$1" "$T/it.yaml" >/dev/null 2>&1; }
{ [ "${rc}" -eq 0 ] && iq '.layers[] | select(.id=="terminal")'; } && ok "iterm2 terminal layer" || bad "iterm2 terminal layer (rc ${rc})"
iq '.layers[].bindings[] | select(.key=="super+t") | .iterm2 == "native"' && ok "iterm2 global key" || bad "iterm2 global key"
iq '.layers[].bindings[] | select(.key=="alt+left") | .iterm2 == "native"' && ok "iterm2 profile key" || bad "iterm2 profile key"
iq '.layers[].bindings[] | select(.key=="f12")' && ok "iterm2 function key" || bad "iterm2 function key"
[ "$(yq '[.layers[].bindings[] | select(.key=="alt+left")] | length' "$T/it.yaml")" = 1 ] \
  && ok "iterm2 key in two profiles once" || bad "iterm2 key in two profiles once"
[ "$(yq '[.layers[].bindings[] | select(.key=="super+t")] | length' "$T/it.yaml")" = 1 ] \
  && ok "iterm2 key in global and profile once" || bad "iterm2 key in global and profile once"
[ "$(yq -r '.layers[].bindings[] | select(.key=="super+t") | .action' "$T/it.yaml")" = "iTerm2 send text" ] \
  && ok "iterm2 action 12 named" || bad "iterm2 action 12 named ($(yq -r '.layers[].bindings[] | select(.key=="super+t") | .action' "$T/it.yaml"))"
[ "$(yq -r '.layers[].bindings[] | select(.key=="alt+left") | .action' "$T/it.yaml")" = "iTerm2 send hex codes: 0x1b 0x62 (profile Default)" ] \
  && ok "iterm2 action with text and profile" || bad "iterm2 action with text and profile ($(yq -r '.layers[].bindings[] | select(.key=="alt+left") | .action' "$T/it.yaml"))"
iq '.layers[].bindings[] | select(.key=="f12") | .action == "iTerm2 send escape sequence: [24~"' \
  && ok "iterm2 action 10 named" || bad "iterm2 action 10 named"
iq '.layers[].bindings[] | select(.key=="super+a") | .action | test("^iTerm2 send text: a very long")' \
  && ok "iterm2 long text kept short" || bad "iterm2 long text kept short"
[ "$(yq -r '.layers[].bindings[] | select(.key=="super+a") | .action | length' "$T/it.yaml")" -le 80 ] \
  && ok "iterm2 action length bounded" || bad "iterm2 action length bounded"
grep -q '^ *# UNMAPPED iterm2: 0xf710-0x0-0x0 (99)' "$T/it.yaml" \
  && ok "iterm2 undecodable key reported with action number" || bad "iterm2 undecodable key reported with action number"
[ "$(grep -c '^capture: INFO iterm2: parsed from preferences; verified against a fixture only, check the output on a Mac$' "$T/err")" = 1 ] \
  && [ "$(wc -l < "$T/err" | tr -d ' ')" = 1 ] && ok "iterm2 verify note once" || bad "iterm2 verify note once ($(cat "$T/err"))"
# --all adds nothing (iTerm2 stores only what the user changed)
out2=$(CAPTURE_ITERM2_JSON="$T/iterm.json" "${CAP}" --all iterm2 2>/dev/null)
[ "${out2}" = "${out}" ] && ok "iterm2 --all same as default" || bad "iterm2 --all same as default"
# odd shapes: never an error, never a yq failure
n=0
for shape in '{}' '[]' '"str"' 'null' '{"GlobalKeyMap": "x", "New Bookmarks": null}' \
             '{"GlobalKeyMap": null, "New Bookmarks": "x"}' '{"GlobalKeyMap": [1], "New Bookmarks": {"a": 1}}' \
             '{"GlobalKeyMap": {"0x74-0x100000-0x11": "oops", "garbage": {"Action": 1}}}'; do
  n=$((n + 1)); printf '%s\n' "${shape}" > "$T/it-odd.json"
  rc=0; out=$(CAPTURE_ITERM2_JSON="$T/it-odd.json" "${CAP}" iterm2 2>"$T/err") || rc=$?
  { [ "${rc}" -eq 0 ] && printf '%s\n' "${out}" | yq -e '.layers' >/dev/null 2>&1 && ! grep -qi 'error' "$T/err"; } \
    && ok "iterm2 odd shape ${n} tolerated" || bad "iterm2 odd shape ${n} tolerated (rc ${rc}: $(cat "$T/err"))"
done
printf '%s\n' '{"GlobalKeyMap": {"garbage": {"Action": 1}}}' > "$T/it-odd.json"
out=$(CAPTURE_ITERM2_JSON="$T/it-odd.json" "${CAP}" iterm2 2>/dev/null)
printf '%s\n' "${out}" | grep -q '^ *# UNMAPPED iterm2: garbage (1)' && ok "iterm2 garbage key reported" || bad "iterm2 garbage key reported"
printf '%s\n' '{}' > "$T/it-odd.json"
rc=0; out=$(CAPTURE_ITERM2_JSON="$T/it-odd.json" "${CAP}" iterm2 2>"$T/err") || rc=$?
{ [ "${rc}" -eq 0 ] && [ "$(grep -c '^capture: INFO iterm2: no user-defined' "$T/err")" = 1 ]; } \
  && ok "iterm2 no mappings INFO" || bad "iterm2 no mappings INFO"
# missing / empty / unparseable seam file: one "not detected" INFO, exit 0
: > "$T/it-empty.json"; printf 'not json {' > "$T/it-bad.json"
for f in "$T/none.json" "$T/it-empty.json" "$T/it-bad.json"; do
  rc=0; out=$(CAPTURE_ITERM2_JSON="${f}" "${CAP}" iterm2 2>"$T/err") || rc=$?
  { [ "${rc}" -eq 0 ] && [ "$(grep -c '^capture: INFO iterm2: not detected' "$T/err")" = 1 ] \
    && [ "$(wc -l < "$T/err" | tr -d ' ')" = 1 ] && printf '%s\n' "${out}" | yq -e '.layers' >/dev/null 2>&1; } \
    && ok "iterm2 absent INFO ($(basename "${f}"))" || bad "iterm2 absent INFO ($(basename "${f}"): rc ${rc}: $(cat "$T/err"))"
done
# the real default invocation: no seam.  Only meaningful where defaults/plutil are missing (not macOS).
if ! command -v defaults >/dev/null 2>&1 || ! command -v plutil >/dev/null 2>&1; then
  rc=0; out=$(env -u CAPTURE_ITERM2_JSON "${CAP}" iterm2 2>"$T/err") || rc=$?
  { [ "${rc}" -eq 0 ] && [ "$(wc -l < "$T/err" | tr -d ' ')" = 1 ] \
    && grep -q '^capture: INFO iterm2: not detected (.*), nothing captured$' "$T/err" \
    && printf '%s\n' "${out}" | yq -e '.layers' >/dev/null 2>&1; } \
    && ok "real iterm2 default: one not-detected INFO" || bad "real iterm2 default: one not-detected INFO (rc ${rc}: $(cat "$T/err"))"
fi
# stub defaults/plutil: the macOS call path (defaults export to a file, plutil -extract per key path)
mkdir -p "$T/bin3"
for tool in uname mktemp rm find sed awk tr cat grep head tail cp yq which dirname wc cut sort uniq mkdir; do
  p=$(command -v "${tool}") && ln -sf "${p}" "$T/bin3/${tool}"
done
# stub "plist" is the fixture JSON itself; plutil -extract KEYPATH json|raw -o - FILE reads it with yq
cat > "$T/bin3/defaults" <<EOF
#!/bin/sh
[ "\$1" = export ] && [ "\$2" = com.googlecode.iterm2 ] || exit 1
[ -n "\${STUB_NODOMAIN:-}" ] && exit 1
cp "$T/iterm.json" "\$3"
EOF
cat > "$T/bin3/plutil" <<'EOF'
#!/bin/sh
[ "$1" = -extract ] || exit 1
kp=$2; fmt=$3; file=$6
expr=.$(printf '%s' "${kp}" | awk -F. '{ for (i = 1; i <= NF; i++) { if ($i ~ /^[0-9]+$/) printf "[%s]", $i; else printf "[\"%s\"]", $i } }')
v=$(yq -o=json -I=0 "${expr}" "${file}" 2>/dev/null) || exit 1
[ "${v}" = null ] && exit 1
# raw: a string as itself, an array or dict as its element count (as the real plutil does)
if [ "${fmt}" = raw ]; then yq -r "${expr} | (select(tag == \"!!seq\" or tag == \"!!map\") | length) // ." "${file}"; else printf '%s\n' "${v}"; fi
EOF
chmod +x "$T/bin3/defaults" "$T/bin3/plutil"
rc=0; out=$(PATH="$T/bin3" "$(command -v bash)" "${CAP}" iterm2 2>"$T/err") || rc=$?
printf '%s\n' "${out}" > "$T/it2.yaml"
{ [ "${rc}" -eq 0 ] && yq -e '.layers[].bindings[] | select(.key=="alt+left") | .action == "iTerm2 send hex codes: 0x1b 0x62 (profile Default)"' "$T/it2.yaml" >/dev/null 2>&1 \
  && yq -e '.layers[].bindings[] | select(.key=="super+t")' "$T/it2.yaml" >/dev/null 2>&1 \
  && grep -q 'UNMAPPED iterm2: 0xf710-0x0-0x0 (99)' "$T/it2.yaml"; } \
  && ok "iterm2 defaults/plutil path (stubbed)" || bad "iterm2 defaults/plutil path (stubbed) (rc ${rc}: $(cat "$T/err"))"
rc=0; STUB_NODOMAIN=1 PATH="$T/bin3" "$(command -v bash)" "${CAP}" iterm2 >/dev/null 2>"$T/err" || rc=$?
{ [ "${rc}" -eq 0 ] && [ "$(grep -c '^capture: INFO iterm2: not detected' "$T/err")" = 1 ] && [ "$(wc -l < "$T/err" | tr -d ' ')" = 1 ]; } \
  && ok "iterm2 no preferences domain INFO" || bad "iterm2 no preferences domain INFO (rc ${rc}: $(cat "$T/err"))"

# ---------------------------------------------------------------------------------------
# tmux baseline: a failing pristine server must never silence the output; concurrent runs
# must not share a pristine server.
mkdir -p "$T/shim"
cat > "$T/shim/tmux" <<EOF
#!/bin/sh
case " \$* " in *" -L capture-pristine"*) exit 1 ;; esac
exec "$(command -v tmux)" "\$@"
EOF
chmod +x "$T/shim/tmux"
tmux -L "${SOCK}" -f /dev/null new-session -d -s b1
tmux -L "${SOCK}" bind -n M-q kill-pane
rc=0; PATH="$T/shim:$PATH" CAPTURE_TMUX_SOCKET="${SOCK}" "${CAP}" tmux > "$T/bf.yaml" 2> "$T/bf.err" || rc=$?
{ [ "${rc}" -eq 0 ] && grep -q '^capture: WARNING tmux: could not read pristine defaults; showing all bindings$' "$T/bf.err"; } \
  && ok "baseline failure warns" || bad "baseline failure warns (rc ${rc}: $(cat "$T/bf.err"))"
yq -e '.layers[].bindings[] | select(.key=="alt+q")' "$T/bf.yaml" >/dev/null 2>&1 \
  && yq -e '.layers[].bindings[] | select(.key=="ctrl+b")' "$T/bf.yaml" >/dev/null 2>&1 \
  && ok "baseline failure falls back to every binding" || bad "baseline failure falls back to every binding"
# six at once against the one server
i=0
while [ "${i}" -lt 6 ]; do
  CAPTURE_TMUX_SOCKET="${SOCK}" "${CAP}" tmux > "$T/par.$i.yaml" 2> "$T/par.$i.err" &
  i=$((i + 1))
done
wait
same=1; i=0
while [ "${i}" -lt 6 ]; do
  cmp -s "$T/par.0.yaml" "$T/par.$i.yaml" || same=0
  i=$((i + 1))
done
{ [ "${same}" -eq 1 ] && yq -e '.layers[].bindings[] | select(.key=="alt+q")' "$T/par.0.yaml" >/dev/null 2>&1; } \
  && ok "6 concurrent captures: identical, non-empty" || bad "6 concurrent captures: identical, non-empty"
n=$(find "$TMUX_TMPDIR" -name 'capture-pristine*' 2>/dev/null | wc -l | tr -d ' ')
[ "${n}" = 0 ] && ok "no pristine server left behind" || bad "no pristine server left behind (${n})"
# the pristine server's session runs an inert command, not the user's interactive shell
mkdir -p "$T/logshim"
cat > "$T/logshim/tmux" <<EOF
#!/bin/sh
case " \$* " in *" -L capture-pristine"*) echo "\$*" >> "$T/logshim.log" ;; esac
exec "$(command -v tmux)" "\$@"
EOF
chmod +x "$T/logshim/tmux"
PATH="$T/logshim:$PATH" CAPTURE_TMUX_SOCKET="${SOCK}" "${CAP}" tmux >/dev/null 2>&1 || :
grep -q 'new-session -d -s base sleep' "$T/logshim.log" 2>/dev/null \
  && ok "pristine session runs an inert command" || bad "pristine session runs an inert command"
# tables: off is kept as table: off, every other table is reported, not dropped
tmux -L "${SOCK}" bind -T off M-x display-message offtab \; bind -T mytab a display-message x \; bind -T copy-mode M-w send -X cancel
CAPTURE_TMUX_SOCKET="${SOCK}" "${CAP}" tmux > "$T/tab.yaml" 2>/dev/null
yq -e '.layers[].bindings[] | select(.key=="alt+x" and .tmux.table == "off")' "$T/tab.yaml" >/dev/null 2>&1 \
  && ok "tmux off table captured as table: off" || bad "tmux off table captured as table: off"
grep -q '^ *# UNMAPPED tmux: mytab a$' "$T/tab.yaml" && ok "tmux custom table reported" || bad "tmux custom table reported"
grep -q '^ *# UNMAPPED tmux: copy-mode M-w$' "$T/tab.yaml" && ok "tmux copy-mode (emacs) table reported" || bad "tmux copy-mode (emacs) table reported"
tmux -L "${SOCK}" kill-server

# vim: nothing is written into HOME (no viminfo), and modes the schema cannot express are reported
mkdir -p "$T/vhome2"; printf 'set nocompatible viminfo=\047100\nnnoremap <F7> :Foo<CR>\nonoremap <F9> iw\ncnoremap <F8> y\nsnoremap <F6> z\n' > "$T/vhome2/.vimrc"
printf '%s\n' "# This viminfo file was generated by Vim 9.2." > "$T/vhome2/.viminfo"; touch -t 202001010000 "$T/vhome2/.viminfo"
mt() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }
m1=$(mt "$T/vhome2/.viminfo"); ls -A "$T/vhome2" > "$T/vh.before"
HOME="$T/vhome2" "${CAP}" vim > "$T/vh.yaml" 2>/dev/null || :
ls -A "$T/vhome2" > "$T/vh.after"
{ [ "$(mt "$T/vhome2/.viminfo")" = "${m1}" ] && [ "$(wc -l < "$T/vhome2/.viminfo" | tr -d ' ')" = 1 ] && cmp -s "$T/vh.before" "$T/vh.after"; } \
  && ok "vim capture leaves HOME (viminfo) untouched" || bad "vim capture leaves HOME (viminfo) untouched"
yq -e '.layers[].bindings[] | select(.key=="f7")' "$T/vh.yaml" >/dev/null 2>&1 && ok "vim temp-HOME capture works" || bad "vim temp-HOME capture works"
grep -q '^ *# UNMAPPED vim: o <F9>$' "$T/vh.yaml" && ok "vim operator-pending map reported" || bad "vim operator-pending map reported"
grep -q '^ *# UNMAPPED vim: c <F8>$' "$T/vh.yaml" && ok "vim command-line map reported" || bad "vim command-line map reported"
grep -q '^ *# UNMAPPED vim: s <F6>$' "$T/vh.yaml" && ok "vim select-mode map reported" || bad "vim select-mode map reported"
[ ! -e "$VH/.viminfo" ] && ok "vim runs in the tests wrote no viminfo" || bad "vim runs in the tests wrote no viminfo"

# kitty: non-ASCII keys and key sequences are reported, never emitted as a wrong key
if command -v kitty >/dev/null 2>&1; then
  mkdir -p "$T/kitty2"
  printf 'map kitty_mod+\xc3\xa9 no_op\nmap ctrl+a>x close_window\nmap ctrl+a>y new_tab\nmap alt+q close_window\n' > "$T/kitty2/kitty.conf"
  KITTY_CONFIG_DIRECTORY="$T/kitty2" "${CAP}" kitty > "$T/k2.yaml" 2>/dev/null || :
  grep -q '^ *# UNMAPPED kitty: ctrl+shift+U+00e9 no_op$' "$T/k2.yaml" && ok "kitty non-ASCII key reported" || bad "kitty non-ASCII key reported"
  grep -q '^ *# UNMAPPED kitty: ctrl+a>x close_window$' "$T/k2.yaml" && grep -q '^ *# UNMAPPED kitty: ctrl+a>y new_tab$' "$T/k2.yaml" \
    && ok "kitty key sequences reported, each one" || bad "kitty key sequences reported, each one"
  yq -e '.layers[].bindings[] | select(.key == "ctrl+a" or (.key | test("[?]")))' "$T/k2.yaml" >/dev/null 2>&1 \
    && bad "kitty emits no wrong key" || ok "kitty emits no wrong key"
  yq -e '.layers[].bindings[] | select(.key=="alt+q") | .kitty == "close_window"' "$T/k2.yaml" >/dev/null 2>&1 \
    && ok "kitty plain key still captured" || bad "kitty plain key still captured"
  [ "$(grep -c 'UNMAPPED' "$T/k2.yaml")" = 3 ] && ok "kitty user-only: built-in sequences not reported" || bad "kitty user-only: built-in sequences not reported"
else
  skip "kitty non-ASCII and sequence tests (kitty not installed)"
fi

# yq / zsh details
if command -v zsh >/dev/null 2>&1; then
  mkdir -p "$T/sh5"; printf '%s\n' "bindkey '^E' kill-line" > "$T/sh5/.zshrc"
  out=$(HOME="$T/sh5" "${CAP}" zsh 2>/dev/null)
  printf '%s\n' "${out}" | yq -e '.layers[].bindings[] | select(.key=="ctrl+e") | .zsh == "kill-line"' >/dev/null 2>&1 \
    && ok "zsh rebound key captured" || bad "zsh rebound key captured"
  printf '%s\n' "${out}" | grep -q 'self-insert' && bad "zsh range remnant not reported as a binding" || ok "zsh range remnant not reported as a binding"
else
  skip "zsh range remnant test (zsh not installed)"
fi

# YAML scalars that a parser would read as bool/null/number are quoted, whatever the case
cat > "$T/rc-q.xml" <<'EOF'
<labwc_config><keyboard>
    <keybind key="W-a"><action name="True"/></keybind>
    <keybind key="W-b"><action name="Execute" command="NULL"/></keybind>
    <keybind key="W-c"><action name="Execute" command="Yes "/></keybind>
    <keybind key="W-d"><action name="Close "/></keybind>
    <keybind key="W-e"><action name="Execute" command="On"/></keybind>
</keyboard></labwc_config>
EOF
CAPTURE_LABWC_RC="$T/rc-q.xml" "${CAP}" labwc > "$T/q.yaml" 2>/dev/null
qt() { yq "[.layers[].bindings[] | select(.key==\"$1\") | $2 | tag] | .[0]" "$T/q.yaml"; }
[ "$(qt super+a .action)" = '!!str' ] && ok "action True stays a string" || bad "action True stays a string ($(qt super+a .action))"
[ "$(qt super+b .labwc.command)" = '!!str' ] && ok "value NULL stays a string" || bad "value NULL stays a string ($(qt super+b .labwc.command))"
[ "$(qt super+e .labwc.command)" = '!!str' ] && ok "value On stays a string" || bad "value On stays a string ($(qt super+e .labwc.command))"
[ "$(yq -r '.layers[].bindings[] | select(.key=="super+c") | .labwc.command' "$T/q.yaml")" = "Yes " ] \
  && ok "value with a trailing space kept" || bad "value with a trailing space kept"
[ "$(yq -r '.layers[].bindings[] | select(.key=="super+d") | .action' "$T/q.yaml")" = "Close " ] \
  && ok "action with a trailing space kept" || bad "action with a trailing space kept"

# ---------------------------------------------------------------------------------------
# Round trip: the repo's own rendered fragments, loaded into throwaway apps, come back from
# capture.sh as the same key set that keys.yaml declares (action, group and note text may
# differ; only keys are compared).  A missing key is a failure.  An extra key is a failure
# too, except where noted below.
#
# Out of scope: gnome, gnome-terminal, bash, zsh and iterm2.  They need a live desktop
# session, a dconf database or macOS, and cannot be loaded into a throwaway instance here.
# (labwc is covered above by "repo rc.xml captures every labwc key in keys.yaml".)

# want_keys LAYER-ID YQ-CONDITION: the keys of a layer's bindings that match the condition,
# one per line, sorted.  range: entries are expanded as render.sh's expand() does.  With
# WANT_TABLE=1 each line is KEY|TABLE (tmux table, `root` when none).
want_keys() {
  yq -r ".layers[] | select(.id==\"$1\") | .bindings[] | select($2) | [(.range // \"-\"), (.tmux.table // \"root\"), .key] | join(\"|\")" \
    "${SCRIPT_DIR}/keys.yaml" | while IFS='|' read -r r t k; do
    [ "${WANT_TABLE:-0}" -eq 0 ] && k2="" || k2="|${t}"
    if [ "${r}" = - ]; then
      printf '%s%s\n' "${k}" "${k2}"
    else
      n=${r%-*}
      while [ "${n}" -le "${r#*-}" ]; do printf '%s%s\n' "${k//"%n"/${n}}" "${k2}"; n=$((n + 1)); done
    fi
  done | sort -u
}
# got_keys FILE: the keys in a capture, one per line, sorted.  got_pairs: KEY|TABLE for tmux.
got_keys() { yq -r '.layers[].bindings[].key' "$1" | sort -u; }
got_pairs() { yq -r '.layers[].bindings[] | select(.tmux != null) | .key + "|" + (.tmux.table // "root")' "$1" | sort -u; }
# round_trip NAME WANT-FILE GOT-ALL-FILE GOT-USER-FILE
#   missing: want minus the --all capture (built-ins included, because a repo binding that
#            equals an app default is a default and is dropped from the user-only capture;
#            tmux's prefix-table `]` is one).
#   extra:   the user-only capture minus want (built-ins are dropped, so anything left is a
#            binding the fragment does not declare).
round_trip() {
  [ "$(wc -l < "$2" | tr -d ' ')" -gt 0 ] && ok "$1 round trip: want set not empty" \
    || bad "$1 round trip: want set is empty"
  missing=$(comm -23 "$2" "$3" | tr '\n' ' ')
  extra=$(comm -13 "$2" "$4" | tr '\n' ' ')
  [ -z "${missing}" ] && ok "$1 round trip: no key missing ($(wc -l < "$2" | tr -d ' '))" \
    || bad "$1 round trip, missing: ${missing}"
  [ -z "${extra}" ] && ok "$1 round trip: no extra key" || bad "$1 round trip, extra: ${extra}"
}

# tmux.  Excluded from the want set: the `option:` entry (the prefix key is an option, not a
# binding) and `unbind: true` entries (they remove a default, so nothing is bound).  Keys are
# compared as (key, table) pairs, so a binding that lands in the wrong table, or is lost from
# one, fails even when the same key is bound in another table.
tmux -L "${SOCK}" -f "${SCRIPT_DIR}/.tmux/keys.conf" new-session -d -s rt
WANT_TABLE=1 want_keys tmux '.tmux != null and .tmux.option == null and (.tmux.unbind // false) == false' > "$T/tmux.want"
CAPTURE_TMUX_SOCKET="${SOCK}" "${CAP}" --all tmux 2>/dev/null > "$T/tmux.all.yaml"
CAPTURE_TMUX_SOCKET="${SOCK}" "${CAP}" tmux 2>/dev/null > "$T/tmux.user.yaml"
tmux -L "${SOCK}" kill-server
got_pairs "$T/tmux.all.yaml" > "$T/tmux.all"; got_pairs "$T/tmux.user.yaml" > "$T/tmux.user"
round_trip tmux "$T/tmux.want" "$T/tmux.all" "$T/tmux.user"

# vim, started with the repo's own .vimrc (which ends with `runtime keys.vim`).  Alt-letter
# keys that keys.vim declares with `set <M-x>` are key codes, not maps, and are not captured;
# keys.yaml's vim layer has none of them as entries, so nothing needs excluding.
if command -v vim >/dev/null 2>&1; then
  want_keys vim '.vim != null' > "$T/vim.want"
  HOME="$VH" CAPTURE_VIM_ARGS="-u ${SCRIPT_DIR}/.vimrc" "${CAP}" --all vim 2>/dev/null > "$T/vim.all.yaml"
  HOME="$VH" CAPTURE_VIM_ARGS="-u ${SCRIPT_DIR}/.vimrc" "${CAP}" vim 2>/dev/null > "$T/vim.user.yaml"
  got_keys "$T/vim.all.yaml" > "$T/vim.all"; got_keys "$T/vim.user.yaml" > "$T/vim.user"
  round_trip vim "$T/vim.want" "$T/vim.all" "$T/vim.user"
else
  skip "vim round trip (vim not installed)"
fi

# kitty, with a config directory whose kitty.conf only includes the repo fragment.
# --all adds kitty's several dozen built-in shortcuts, which is why extras are judged on the
# user-only capture.
if command -v kitty >/dev/null 2>&1; then
  mkdir -p "$T/kcfg"; echo "include ${SCRIPT_DIR}/.config/kitty/keys.conf" > "$T/kcfg/kitty.conf"
  want_keys terminal '.kitty != null' > "$T/kitty.want"
  KITTY_CONFIG_DIRECTORY="$T/kcfg" "${CAP}" --all kitty 2>/dev/null > "$T/kitty.all.yaml"
  KITTY_CONFIG_DIRECTORY="$T/kcfg" "${CAP}" kitty 2>/dev/null > "$T/kitty.user.yaml"
  got_keys "$T/kitty.all.yaml" > "$T/kitty.all"; got_keys "$T/kitty.user.yaml" > "$T/kitty.user"
  round_trip kitty "$T/kitty.want" "$T/kitty.all" "$T/kitty.user"
else
  skip "kitty round trip (kitty not installed)"
fi

# ---------------------------------------------------------------------------------------
# Absent-app sweep: a PATH holding only the basic tools capture.sh itself needs (no tmux,
# kitty, vim, zsh, gsettings, dconf, defaults or plutil) and an empty HOME.  Exit 0, an empty
# layer list, and exactly one INFO line per app.
#
# bash is the one exception: it is always present (capture.sh is itself a bash script), so it
# cannot be "not detected".  It is asserted separately: with an empty HOME it must say it
# found no user-defined bindings, once.  The other eight apps must each say "not detected".
mkdir -p "$T/sbin" "$T/shome"
for t in bash sh awk sed grep cat mktemp rm tr sort dirname uname head tail wc cut mkdir id basename yq ls readlink expr which find env; do
  p=$(type -P "$t") && ln -s "${p}" "$T/sbin/$t"
done
rc=0; env -i PATH="$T/sbin" HOME="$T/shome" "${CAP}" > "$T/sweep.out" 2> "$T/sweep.err" || rc=$?
[ "${rc}" -eq 0 ] && ok "all apps absent: exit 0" || bad "all apps absent: exit 0 (got ${rc})"
[ "$(yq '.layers | length' "$T/sweep.out" 2>/dev/null)" = 0 ] \
  && ok "all apps absent: layers: []" || bad "all apps absent: layers: []"
for a in labwc gnome kitty gnome-terminal iterm2 tmux zsh vim; do
  n=$(grep -c "^capture: INFO ${a}: not detected (.*), nothing captured\$" "$T/sweep.err")
  [ "${n}" = 1 ] && ok "absent ${a}: one 'not detected' line" || bad "absent ${a}: one 'not detected' line (got ${n})"
done
n=$(grep -c '^capture: INFO bash: no user-defined bindings found' "$T/sweep.err")
[ "${n}" = 1 ] && ok "bash (always present): one 'no user-defined bindings' line" || bad "bash (always present): one 'no user-defined bindings' line (got ${n})"
n=$(grep -c '^capture: INFO os: not captured (no live binding list), nothing captured$' "$T/sweep.err")
[ "${n}" = 1 ] && ok "no-args run: one 'os not captured' line" || bad "no-args run: one 'os not captured' line (got ${n})"
n=$(wc -l < "$T/sweep.err" | tr -d ' ')
[ "${n}" = 10 ] && ok "all apps absent: nothing else on stderr (10 lines)" || bad "all apps absent: nothing else on stderr (got ${n}: $(cat "$T/sweep.err"))"
# naming apps does not print the os line
env -i PATH="$T/sbin" HOME="$T/shome" "${CAP}" vim tmux > /dev/null 2> "$T/named.err" || :
grep -q 'INFO os:' "$T/named.err" && bad "named apps: no os line" || ok "named apps: no os line"

# shell readers need yq: without it they say so instead of reporting everything as unmapped
mkdir -p "$T/sbin2"
for f in "$T/sbin"/*; do [ "$(basename "$f")" = yq ] || ln -s "$(readlink "$f")" "$T/sbin2/$(basename "$f")"; done
mkdir -p "$T/sh6"; printf '%s\n' "bind '\"\\C-q\": kill-line'" > "$T/sh6/.bashrc"
rc=0; env -i PATH="$T/sbin2" HOME="$T/sh6" INPUTRC=/dev/null "${CAP}" bash > "$T/noyq.yaml" 2> "$T/noyq.err" || rc=$?
{ [ "${rc}" -eq 0 ] && [ "$(grep -c '^capture: WARNING shell: yq not found, byte sequences cannot be mapped to key names$' "$T/noyq.err")" = 1 ]; } \
  && ok "shell reader warns once when yq is missing" || bad "shell reader warns once when yq is missing (rc ${rc}: $(cat "$T/noyq.err"))"

[ "${FAIL}" -eq 0 ] && echo "capture: all passed"
exit "${FAIL}"
