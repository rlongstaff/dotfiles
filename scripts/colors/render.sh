#!/usr/bin/env bash
#
# Render colors.yaml into every app's own config syntax.
#
#   scripts/colors/render.sh           write whatever changed, report each file
#   scripts/colors/render.sh --check   write nothing; exit 1 if anything is stale
#
# colors.yaml is the single source of truth for colours.  The fragments below are
# GENERATED and committed, so a machine without yq still has working configs; yq is only
# needed here, to re-render after editing the yaml.
#
#   .config/kitty/colors.conf        kitty.conf:  include colors.conf
#   .tmux/colors.conf                .tmux.conf:  source-file ~/.tmux/colors.conf
#   .shell/.common.d/colors.sh       .common.d loader; .bashrc and the zsh theme build
#                                    the prompt from it
#   .vim/colors.vim                  .vimrc:      runtime colors.vim
#   docs/colors-cheatsheet.md        palette, where each colour is used, per-layer tables
#
# Every app is handed a colour NUMBER (or hex), never a name: vim's 'Blue' is 12 and
# tmux's 'blue' is 4, so names in the yaml are resolved against its own palette here.
#
# Idempotent: each target is rendered to a temp file and replaced only when it differs.
# Writes only inside the checkout (SCRIPT_DIR), never into $HOME -- see scripts/check.sh.
#
# bash 3.2 safe (macOS): no associative arrays, no mapfile, no ${x,,}.  Requires
# mikefarah yq v4 (Go), not the python yq wrapper -- they share a name, not a language.

set -eu
set -f

: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
MODULE=colors
. "${SCRIPT_DIR}/scripts/lib.sh"

YAML="${SCRIPT_DIR}/colors.yaml"

OUT_KITTY="${SCRIPT_DIR}/.config/kitty/colors.conf"
OUT_TMUX="${SCRIPT_DIR}/.tmux/colors.conf"
OUT_SHELL="${SCRIPT_DIR}/.shell/.common.d/colors.sh"
OUT_VIM="${SCRIPT_DIR}/.vim/colors.vim"
OUT_DOCS="${SCRIPT_DIR}/docs/colors-cheatsheet.md"

CHECK=""
case "${1:-}" in
  --check) CHECK=1 ;;
  "") ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac

US=$(printf '\037')     # field separator: non-whitespace, so empty fields survive `read`
STALE=0
TMPD=$(mktemp -d)
trap 'rm -rf "${TMPD}"' EXIT
USES="${TMPD}/uses"     # "index<US>layer<US>key<US>role" per palette colour used
: > "${USES}"

die() { echo "render: $*" >&2; exit 1; }

yq --version 2>/dev/null | grep -q 'mikefarah.* v4' \
  || die "needs mikefarah yq v4 (https://github.com/mikefarah/yq); found: $(yq --version 2>&1 | head -1)"
[ -f "${YAML}" ] || die "missing ${YAML}"

GEN_NOTE="GENERATED from colors.yaml by scripts/colors/render.sh. Edit the yaml, not this file."

# --------------------------------------------------------------------------------------
# Palette and colour values
# --------------------------------------------------------------------------------------

PALETTE_NAMES=$(yq -r '.palette[].name' "${YAML}" | tr '\n' ' ')
PALETTE_HEX=$(yq -r '.palette[].hex' "${YAML}" | tr '\n' ' ')
[ "$(echo ${PALETTE_NAMES} | wc -w)" -eq 16 ] || die "palette: needs exactly 16 colours"

# nth N LIST -> the Nth (0-based) word of LIST
nth() { local n=$1; shift; set -- $1; shift "${n}"; printf '%s\n' "$1"; }

# resolve WHERE VALUE -> sets KIND (idx|hex|kw) and IDX / HEX; dies on anything else.
KEYWORDS=" none default system background foreground "
resolve() {
  local rv=$2 ri=0 rname
  KIND=""; IDX=""; HEX=""
  for rname in ${PALETTE_NAMES}; do
    if [ "${rname}" = "${rv}" ]; then KIND=idx; IDX=${ri}; return 0; fi
    ri=$((ri + 1))
  done
  case "${rv}" in
    ''|*[!0-9]*) ;;
    *) [ "${rv}" -le 255 ] || die "$1: colour number ${rv} is out of range 0-255"
       KIND=idx; IDX=${rv}; return 0 ;;
  esac
  if printf '%s' "${rv}" | grep -qiE '^#[0-9a-f]{6}$'; then KIND=hex; HEX=${rv}; return 0; fi
  case "${KEYWORDS}" in *" ${rv} "*) KIND=kw; return 0 ;; esac
  die "$1: '${rv}' is not a palette name, 0-255, #rrggbb or keyword"
}

# use LAYER KEY ROLE -- record that the last resolved colour is used here (for the docs)
use() { [ "${KIND}" != idx ] || printf '%s%s%s%s%s%s%s\n' "${IDX}" "${US}" "$1" "${US}" "$2" "${US}" "$3" >> "${USES}"; }

# xterm-256 index -> #rrggbb (0-15 from the palette)
idx_hex() {
  local g c lv
  if [ "$1" -lt 16 ]; then nth "$1" "${PALETTE_HEX}"; return; fi
  if [ "$1" -ge 232 ]; then g=$((8 + ($1 - 232) * 10)); printf '#%02x%02x%02x\n' "${g}" "${g}" "${g}"; return; fi
  c=$(($1 - 16)); lv="0 95 135 175 215 255"
  printf '#%02x%02x%02x\n' "$(nth $((c / 36)) "${lv}")" "$(nth $((c / 6 % 6)) "${lv}")" "$(nth $((c % 6)) "${lv}")"
}

kitty_col() { resolve "$1" "$2"; case "${KIND}" in idx) idx_hex "${IDX}" ;; hex) echo "${HEX}" ;; kw) echo "$2" ;; esac; }
tmux_col()  { resolve "$1" "$2"; case "${KIND}" in idx) echo "colour${IDX}" ;; hex) echo "${HEX}" ;; kw) echo "$2" ;; esac; }
vim_col() {
  resolve "$1" "$2"
  case "${KIND}" in
    idx) echo "${IDX}" ;;
    kw)  case "$2" in none) echo NONE ;; *) die "$1: vim has no colour '$2'" ;; esac ;;
    hex) die "$1: vim runs without 'termguicolors'; use a palette name or 0-255, not $2" ;;
  esac
}
# SGR parameter for a foreground (fg) or background (bg) colour
sgr_col() {
  resolve "$1" "$3"
  [ "${KIND}" = idx ] || die "$1: the shells take a palette name or 0-255, not $3"
  if [ "${IDX}" -lt 8 ]; then
    [ "$2" = fg ] && echo $((30 + IDX)) || echo $((40 + IDX))
  elif [ "${IDX}" -lt 16 ]; then
    [ "$2" = fg ] && echo $((90 + IDX - 8)) || echo $((100 + IDX - 8))
  else
    [ "$2" = fg ] && echo "38;5;${IDX}" || echo "48;5;${IDX}"
  fi
}
sgr_attr() {
  case "$2" in
    bold) echo 1 ;; dim) echo 2 ;; italic) echo 3 ;; underline) echo 4 ;; blink) echo 5 ;;
    reverse) echo 7 ;; strikethrough) echo 9 ;;
    *) die "$1: the shells have no attribute '$2'" ;;
  esac
}

# --------------------------------------------------------------------------------------
# Output plumbing (as scripts/keyboard/render.sh)
# --------------------------------------------------------------------------------------

finish() {
  rel=${2#"${SCRIPT_DIR}/"}
  if [ -f "$2" ] && cmp -s "$1" "$2"; then
    log "unchanged ${rel}"
  elif [ -n "${CHECK}" ]; then
    log "STALE     ${rel}"
    STALE=1
  else
    mkdir -p "$(dirname -- "$2")"
    cat "$1" > "$2"
    log "updated   ${rel}"
  fi
}

# entries LAYER LIST -- one line per entry of that layer's LIST:
#   key, value, fg, bg, attrs (comma list), link, note, about, section
entries() {
  yq -r ".layers[] | select(.id == \"$1\") | .$2
         | ((select(tag == \"!!seq\") | .[]),
            (select(tag == \"!!map\") | to_entries[] | .key as \$s | .value[] | . + {\"_s\": \$s}))
         | [(.key // .group // \"\"), (.value // \"\" | tostring), (.fg // \"\" | tostring),
            (.bg // \"\" | tostring), ((.attrs // []) | join(\",\")), (.link // \"\"),
            (.note // \"\"), (.about // \"\"), (._s // \"\")] | join(\"${US}\")" "${YAML}"
}

# --------------------------------------------------------------------------------------
# kitty
# --------------------------------------------------------------------------------------

render_kitty() {
  t="${TMPD}/kitty"
  {
    echo "# ${GEN_NOTE}"
    echo "# Included by kitty.conf."
    echo
    echo "# -- palette ---------------------------------------------------------------------"
    i=0
    for name in ${PALETTE_NAMES}; do
      printf 'color%-3s %s  # %s\n' "${i}" "$(nth "${i}" "${PALETTE_HEX}")" "${name}"
      i=$((i + 1))
    done
    echo
    echo "# -- ui --------------------------------------------------------------------------"
    entries kitty settings | while IFS="${US}" read -r key val fg bg attrs link note about sec; do
      [ -n "${val}" ] || continue
      c=$(kitty_col "kitty: ${key}" "${val}")
      resolve "kitty: ${key}" "${val}"; use kitty "${key}" ""
      [ -z "${note}" ] || echo "# ${note}"
      printf '%-24s %s\n' "${key}" "${c}"
    done
  } > "${t}"
  finish "${t}" "${OUT_KITTY}"
}

# --------------------------------------------------------------------------------------
# tmux
# --------------------------------------------------------------------------------------

tmux_style() {   # WHERE FG BG ATTRS -> fg=..,bg=..,attr
  local s=""
  [ -z "$2" ] || s="fg=$(tmux_col "$1" "$2")"
  [ -z "$3" ] || s="${s:+${s},}bg=$(tmux_col "$1" "$3")"
  [ -z "$4" ] || s="${s:+${s},}$4"
  printf '%s\n' "${s}"
}

render_tmux() {
  t="${TMPD}/tmux"
  {
    echo "# ${GEN_NOTE}"
    echo "# Sourced by .tmux.conf.  Restart tmux (tmux kill-server) after a change."
    entries tmux settings | while IFS="${US}" read -r key val fg bg attrs link note about sec; do
      [ -n "${val}${fg}${bg}${attrs}" ] || continue
      echo
      [ -z "${note}" ] || echo "# ${note}"
      if [ -n "${val}" ]; then
        v=$(tmux_col "tmux: ${key}" "${val}"); resolve "tmux: ${key}" "${val}"; use tmux "${key}" ""
      else
        v=$(tmux_style "tmux: ${key}" "${fg}" "${bg}" "${attrs}")
        if [ -n "${fg}" ]; then resolve "tmux: ${key}" "${fg}"; use tmux "${key}" fg; fi
        if [ -n "${bg}" ]; then resolve "tmux: ${key}" "${bg}"; use tmux "${key}" bg; fi
      fi
      echo "set -g ${key} \"${v}\""
    done
  } > "${t}"
  finish "${t}" "${OUT_TMUX}"
}

# --------------------------------------------------------------------------------------
# shells
# --------------------------------------------------------------------------------------

# BSD LSCOLORS letter for a colour: a..h for the eight base colours, x for none
bsd_letter() {
  [ -n "$2" ] || { echo x; return; }
  resolve "$1" "$2"
  [ "${KIND}" = idx ] && [ "${IDX}" -lt 8 ] \
    || die "$1: LSCOLORS (BSD ls) has only the eight base colours, not $2"
  nth "${IDX}" "a b c d e f g h"
}

render_shell() {
  t="${TMPD}/shell"
  gnu=""
  bsd_slots="di ln so pi ex bd cd su sg tw ow"
  bsd=""
  for slot in ${bsd_slots}; do
    line=$(entries shell ls | awk -F"${US}" -v k="${slot}" '$1 == k' || true)
    fg=$(printf '%s' "${line}" | cut -d"${US}" -f3)
    bg=$(printf '%s' "${line}" | cut -d"${US}" -f4)
    attrs=$(printf '%s' "${line}" | cut -d"${US}" -f5)
    f=$(bsd_letter "ls: ${slot}" "${fg}")
    case ",${attrs}," in *,bold,*) f=$(printf '%s' "${f}" | tr 'a-h' 'A-H') ;; esac
    bsd="${bsd}${f}$(bsd_letter "ls: ${slot}" "${bg}")"
  done
  while IFS="${US}" read -r key val fg bg attrs link note about sec; do
    p=""
    for a in $(echo "${attrs}" | tr ',' ' '); do p="${p:+${p};}$(sgr_attr "ls: ${key}" "${a}")"; done
    if [ -n "${fg}" ]; then p="${p:+${p};}$(sgr_col "ls: ${key}" fg "${fg}")"; resolve "" "${fg}"; use shell "ls ${key}" fg; fi
    if [ -n "${bg}" ]; then p="${p:+${p};}$(sgr_col "ls: ${key}" bg "${bg}")"; resolve "" "${bg}"; use shell "ls ${key}" bg; fi
    gnu="${gnu:+${gnu}:}${key}=${p}"
  done <<EOF
$(entries shell ls)
EOF
  {
    echo "# ${GEN_NOTE}"
    echo "# Sourced by both shells through the .common.d loader, and by the zsh theme, which"
    echo "# runs before that loader.  Plain assignments: sourcing it twice is harmless."
    echo
    echo "# -- ls --------------------------------------------------------------------------"
    echo "export CLICOLOR=1"
    echo "export LS_COLORS='${gnu}'"
    echo "export LSCOLORS=${bsd}"
    echo
    echo "# -- prompt ----------------------------------------------------------------------"
    echo "# bash: \\[ \\e[..m \\] wrapped, ready to splice into PS1.  zsh: an on / off pair."
    while IFS="${US}" read -r key val fg bg attrs link note about sec; do
      [ -n "${fg}${attrs}" ] || continue
      p=""; zon=""; zoff=""
      for a in $(echo "${attrs}" | tr ',' ' '); do
        p="${p:+${p};}$(sgr_attr "prompt: ${key}" "${a}")"
        case "${a}" in
          bold) zon="${zon}%B"; zoff="%b${zoff}" ;;
          underline) zon="${zon}%U"; zoff="%u${zoff}" ;;
          *) die "prompt: ${key}: zsh prompts have no '${a}'" ;;
        esac
      done
      if [ -n "${fg}" ]; then
        p="${p:+${p};}$(sgr_col "prompt: ${key}" fg "${fg}")"
        resolve "" "${fg}"; use shell "prompt ${key}" fg
        zon="${zon}%F{${IDX}}"; zoff="%f${zoff}"
      fi
      v=$(printf '%s' "${key}" | tr 'a-z' 'A-Z')
      printf "DOTFILES_C_BASH_%s='\\\\[\\\\e[%sm\\\\]'\n" "${v}" "${p}"
      printf "DOTFILES_C_ZSH_%s='%s'\n" "${v}" "${zon}"
      printf "DOTFILES_C_ZSH_%s_OFF='%s'\n" "${v}" "${zoff}"
    done <<EOF
$(entries shell prompt)
EOF
  } > "${t}"
  finish "${t}" "${OUT_SHELL}"
}

# --------------------------------------------------------------------------------------
# vim
# --------------------------------------------------------------------------------------

VIM_ATTRS=" bold underline undercurl underdouble underdotted underdashed strikethrough reverse inverse italic standout nocombine NONE "

render_vim() {
  t="${TMPD}/vim"
  last=""
  {
    echo "\" ${GEN_NOTE}"
    echo "\" Sourced by .vimrc (runtime colors.vim).  Re-applied on ColorScheme, which clears"
    echo "\" every group, and on VimEnter, after plugins have defined their own defaults."
    echo
    echo "function! s:apply() abort"
    entries vim groups | while IFS="${US}" read -r key val fg bg attrs link note about sec; do
      [ -n "${fg}${bg}${attrs}${link}" ] || continue
      if [ "${sec}" != "${last}" ]; then echo "  \" -- ${sec}"; last=${sec}; fi
      [ -z "${note}" ] || echo "  \" ${note}"
      if [ -n "${link}" ]; then
        echo "  highlight! link ${key} ${link}"
        continue
      fi
      h="highlight ${key}"
      if [ -n "${fg}" ]; then h="${h} ctermfg=$(vim_col "vim: ${key}" "${fg}")"; resolve "" "${fg}"; use vim "${key}" fg; fi
      if [ -n "${bg}" ]; then h="${h} ctermbg=$(vim_col "vim: ${key}" "${bg}")"; resolve "" "${bg}"; use vim "${key}" bg; fi
      if [ -n "${attrs}" ]; then
        for a in $(echo "${attrs}" | tr ',' ' '); do
          case "${VIM_ATTRS}" in *" ${a} "*) ;; *) die "vim: ${key}: no attribute '${a}'" ;; esac
        done
        h="${h} cterm=${attrs}"
      fi
      echo "  ${h}"
    done
    echo "endfunction"
    echo
    echo "call s:apply()"
    echo "augroup dotfiles_colors"
    echo "  autocmd!"
    echo "  autocmd ColorScheme,VimEnter * call s:apply()"
    echo "augroup END"
  } > "${t}"
  finish "${t}" "${OUT_VIM}"
}

# --------------------------------------------------------------------------------------
# docs
# --------------------------------------------------------------------------------------

md_rows() {   # LAYER LIST -> markdown rows for entries that have a value
  entries "$1" "$2" | while IFS="${US}" read -r key val fg bg attrs link note about sec; do
    [ -n "${val}${fg}${bg}${attrs}${link}" ] || continue
    v=""
    [ -z "${val}" ] || v="${val}"
    [ -z "${fg}" ] || v="${v:+${v} }fg ${fg}"
    [ -z "${bg}" ] || v="${v:+${v} }bg ${bg}"
    [ -z "${attrs}" ] || v="${v:+${v} }${attrs}"
    [ -z "${link}" ] || v="links to ${link}"
    printf '| `%s` | %s | %s | %s |\n' "${key}" "${v}" "${about}" "${note}"
  done
}

render_docs() {
  t="${TMPD}/docs"
  {
    echo "<!-- ${GEN_NOTE} -->"
    echo
    echo "# Colour cheatsheet"
    echo
    echo "Every colour in the dotfiles, generated from \`colors.yaml\` (repo root). Edit the yaml,"
    echo "run \`scripts/colors/render.sh\`, commit both. Only the settings that have a value are"
    echo "listed here; the yaml also lists every setting left at the app's default."
    echo
    echo "## Palette"
    echo
    echo "The 16 terminal colours (kitty's defaults, pinned) and everything that uses each one."
    echo
    echo "| # | Name | Hex | Used by |"
    echo "| - | ---- | --- | ------- |"
    i=0
    for name in ${PALETTE_NAMES}; do
      used=$(awk -F"${US}" -v i="${i}" '$1 == i {
               r = ($4 == "") ? "" : " (" $4 ")"
               printf "%s%s: `%s`%s", sep, $2, $3, r; sep = ", " }' "${USES}")
      printf '| %s | %s | `%s` | %s |\n' "${i}" "${name}" "$(nth "${i}" "${PALETTE_HEX}")" "${used:-}"
      i=$((i + 1))
    done
    for layer in kitty tmux shell vim; do
      title=$(yq -r ".layers[] | select(.id == \"${layer}\") | .title" "${YAML}")
      where=$(yq -r ".layers[] | select(.id == \"${layer}\") | .where" "${YAML}")
      echo
      echo "## ${title}"
      echo
      echo "${where}"
      for list in $(yq -r ".layers[] | select(.id == \"${layer}\") | keys | .[] | select(. != \"id\" and . != \"title\" and . != \"where\")" "${YAML}"); do
        total=$(entries "${layer}" "${list}" | wc -l | tr -d ' ')
        echo
        echo "**${list}** (${total} listed in the yaml)"
        echo
        echo "| Setting | Value | What it colours | Why |"
        echo "| ------- | ----- | ------- | --- |"
        md_rows "${layer}" "${list}"
      done
    done
  } > "${t}"
  finish "${t}" "${OUT_DOCS}"
}

# --------------------------------------------------------------------------------------

render_kitty
render_tmux
render_shell
render_vim
render_docs

if [ -n "${CHECK}" ] && [ "${STALE}" -ne 0 ]; then
  echo "render: generated files are stale; run scripts/colors/render.sh" >&2
  exit 1
fi
