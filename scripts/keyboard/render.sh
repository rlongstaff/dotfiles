#!/usr/bin/env bash
#
# Render keys.yaml into every app's own config syntax.
#
#   scripts/keyboard/render.sh           write whatever changed, report each file
#   scripts/keyboard/render.sh --check   write nothing; exit 1 if anything is stale
#
# keys.yaml is the single source of truth for key bindings.  The fragments below are
# GENERATED and committed, so a machine without yq still has working configs; yq is only
# needed here, to re-render after editing the yaml.
#
#   .config/kitty/keys.conf              kitty.conf:  include keys.conf
#   .tmux/keys.conf                      .tmux.conf:  source-file ~/.tmux/keys.conf
#   .vim/keys.vim                        .vimrc:      runtime keys.vim
#   .shell/.common.d/keys.sh             picked up by the .common.d loader, both shells
#   .config/labwc/rc.xml                 only the block between the GENERATED markers
#   scripts/keyboard/linux/gnome-keys.sh sourced by linux/terminal.sh (gsettings)
#   docs/keyboard-cheatsheet.md       capture-chain table, per-layer tables, shadows
#
# Idempotent: each target is rendered to a temp file and replaced only when it differs.
# Writes only inside the checkout (SCRIPT_DIR), never into $HOME -- see scripts/check.sh.
#
# bash 3.2 safe (macOS): no associative arrays, no mapfile, no ${x,,}.  Requires
# mikefarah yq v4 (Go), not the python yq wrapper -- they share a name, not a language.

set -eu
set -f          # no globbing: keys like M-[ and * must stay literal

: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
MODULE=render
. "${SCRIPT_DIR}/scripts/lib.sh"

YAML="${SCRIPT_DIR}/keys.yaml"

OUT_KITTY="${SCRIPT_DIR}/.config/kitty/keys.conf"
OUT_TMUX="${SCRIPT_DIR}/.tmux/keys.conf"
OUT_VIM="${SCRIPT_DIR}/.vim/keys.vim"
OUT_SHELL="${SCRIPT_DIR}/.shell/.common.d/keys.sh"
OUT_LABWC="${SCRIPT_DIR}/.config/labwc/rc.xml"
OUT_GNOME="${SCRIPT_DIR}/scripts/keyboard/linux/gnome-keys.sh"
OUT_DOCS="${SCRIPT_DIR}/docs/keyboard-cheatsheet.md"

LABWC_BEGIN='<!-- BEGIN GENERATED from keys.yaml by render.sh; edit the yaml -->'
LABWC_END='<!-- END GENERATED -->'

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

die() { echo "render: $*" >&2; exit 1; }

yq --version 2>/dev/null | grep -q 'mikefarah.* v4' \
  || die "needs mikefarah yq v4 (https://github.com/mikefarah/yq); found: $(yq --version 2>&1 | head -1)"
[ -f "${YAML}" ] || die "missing ${YAML}"

# --------------------------------------------------------------------------------------
# Reading the yaml
# --------------------------------------------------------------------------------------

# rows LAYER FILTER FIELDS -- one line per binding of LAYER that passes FILTER, fields
# joined by US.  The first field is always the range, which expand() consumes.
rows() {
  yq -r ".layers[] | select(.id == \"$1\") | .bindings[] | select($2)
         | [(.range // \"\"), $3] | join(\"${US}\")" "${YAML}" | expand
}

# Repeat each line for n in its range, replacing %n; strip the range field.
expand() {
  while IFS= read -r line; do
    r=${line%%"${US}"*}
    rest=${line#*"${US}"}
    if [ -z "${r}" ]; then
      printf '%s\n' "${rest}"
    else
      n=${r%-*}
      while [ "${n}" -le "${r#*-}" ]; do
        printf '%s\n' "${rest//"%n"/${n}}"
        n=$((n + 1))
      done
    fi
  done
}

# --------------------------------------------------------------------------------------
# Canonical key spelling -> each app's spelling
# --------------------------------------------------------------------------------------

# split KEY -> sets MODS ("ctrl alt ...") and BASE.  The base is whatever follows the
# last '+', so 'alt+-' and 'alt+\' parse; a bare key has no modifiers.
split() {
  case "$1" in
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
    f[0-9]*) upper "$1" ;; *) printf '%s\n' "$1" ;;
  esac
}
kitty_name() {
  case "$1" in
    pageup) echo page_up ;; pagedown) echo page_down ;; esc) echo escape ;;
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

xml_esc() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }

# --------------------------------------------------------------------------------------
# Output plumbing
# --------------------------------------------------------------------------------------

GEN_NOTE="GENERATED from keys.yaml by render.sh. Edit the yaml, not this file."

# finish TMPFILE DEST -- install TMPFILE as DEST if it differs; in --check, only report.
finish() {
  rel=${2#"${SCRIPT_DIR}/"}
  if [ -f "$2" ] && cmp -s "$1" "$2"; then
    log "unchanged ${rel}"
  elif [ -n "${CHECK}" ]; then
    log "STALE     ${rel}"
    STALE=1
  else
    mkdir -p "$(dirname -- "$2")"
    cat "$1" > "$2"          # through cat, so a symlinked or executable DEST keeps its inode/mode
    log "updated   ${rel}"
  fi
}

# group_header COMMENT_OPEN GROUP [COMMENT_CLOSE [FILL]] -- a section rule whenever the group
# changes.  Never call it through a pipe: LAST_GROUP has to survive in this shell.
LAST_GROUP=""
group_header() {
  if [ "$2" = "${LAST_GROUP}" ]; then return 0; fi
  LAST_GROUP=$2
  if [ -z "$2" ]; then return 0; fi
  close=${3:-}
  fill=${4:--}     # XML comments may not contain '--', so labwc passes '='
  printf '\n%s %s%s %s %s%s\n' "$1" "${fill}" "${fill}" "$2" \
    "$(printf '%*s' $((78 - ${#1} - ${#2} - ${#close})) '' | tr ' ' "${fill}")" "${close}"
}

# --------------------------------------------------------------------------------------
# Validation: every key in every layer, and every sequence name
# --------------------------------------------------------------------------------------

check_keys() {
  bad=0
  for layer in $(yq -r '.layers[].id' "${YAML}"); do
    while IFS="${US}" read -r key action; do
      [ -n "${action}" ] || { echo "render: ${layer}: '${key}' has no action" >&2; bad=1; }
      why=$(validate "${key}") || { echo "render: ${layer}: '${key}': ${why}" >&2; bad=1; }
    done <<EOF
$(rows "${layer}" 'true' '.key, (.action // "")')
EOF
  done
  for key in $(yq -r '.sequences | keys | .[]' "${YAML}"); do
    why=$(validate "${key}") || { echo "render: sequences: '${key}': ${why}" >&2; bad=1; }
  done
  [ "${bad}" -eq 0 ] || die "keys.yaml has invalid keys; nothing rendered"
}

# --------------------------------------------------------------------------------------
# kitty
# --------------------------------------------------------------------------------------

render_kitty() {
  t="${TMPD}/kitty"
  LAST_GROUP=""
  {
    echo "# ${GEN_NOTE}"
    echo "# Included by kitty.conf.  kitty treats cmd and super as the same modifier."
    rows terminal 'has("kitty")' '.group // "", .note // "", .key, .kitty' |
    while IFS="${US}" read -r group note key act; do
      group_header '#' "${group}"
      [ -z "${note}" ] || echo "# ${note}"
      echo "map $(kitty_key "${key}") ${act}"
    done
  } > "${t}"
  finish "${t}" "${OUT_KITTY}"
}

# --------------------------------------------------------------------------------------
# tmux
# --------------------------------------------------------------------------------------

render_tmux() {
  t="${TMPD}/tmux"
  LAST_GROUP=""
  {
    echo "# ${GEN_NOTE}"
    cat <<'EOF'
# Sourced by .tmux.conf.  Rationale for every choice here: docs/keyboard.md.

# Is the pane running vim?  Deliberately backslash-free: this string is parsed by tmux,
# then sh, then grep, and a '\S' would arrive at grep as a literal backslash.
is_vim="ps -o state=,comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +[^ ]*(vim|vimx|nvim|view)(-wrapped)?(diff)?$'"

# Is the pane running something that pages its own content?  alternate_on alone misses
# less, because LESS=-X (.shell/.common.d/home.sh) keeps it off the alternate screen.
pager_active="#{||:#{alternate_on},#{m/r:^(vim|vimx|nvim|view|less|more|most|man|top|htop|watch|git)$,#{pane_current_command}}}"
EOF
    rows tmux 'has("tmux")' \
      '.group // "", .note // "", .key, (.tmux.table // "root"), (.tmux.cmd // ""),
       (.tmux.pass // ""), ((.tmux.unbind // false) | tostring), (.tmux.option // "")' |
    while IFS="${US}" read -r group note key table cmd pass unbind option; do
      group_header '#' "${group}"
      [ -z "${note}" ] || echo "# ${note}"
      for k in $(tmux_keys "${key}"); do
        q=$(tmux_q "${k}")
        if [ -n "${option}" ]; then
          echo "set -g ${option} ${q}"
          continue
        fi
        case "${table}" in
          root)   bind="bind -n ${q}";              unb="unbind -n ${q}" ;;
          prefix) bind="bind ${q}";                 unb="unbind ${q}" ;;
          copy)   bind="bind -T copy-mode-vi ${q}"; unb="unbind -T copy-mode-vi ${q}" ;;
          *) die "tmux: ${key}: unknown table '${table}'" ;;
        esac
        if [ "${unbind}" = "true" ]; then
          echo "${unb}"
          if [ "${table}" = copy ]; then echo "unbind -T copy-mode ${q}"; fi
          continue
        fi
        case "${pass}" in
          "")    line="${bind} ${cmd}" ;;
          vim)   line="${bind} if-shell \"\$is_vim\" 'send-keys ${k}' '${cmd}'" ;;
          pager) line="${bind} if-shell -F \"\$pager_active\" 'send-keys ${k}' '${cmd}'" ;;
          *) die "tmux: ${key}: unknown pass '${pass}'" ;;
        esac
        echo "${line}"
        if [ "${table}" = copy ]; then echo "bind -T copy-mode ${q} ${cmd}"; fi
      done
    done
  } > "${t}"
  finish "${t}" "${OUT_TMUX}"
}

# --------------------------------------------------------------------------------------
# vim
# --------------------------------------------------------------------------------------

render_vim() {
  t="${TMPD}/vim"
  LAST_GROUP=""
  alt_letters=$(rows vim 'has("vim")' '.key' | while IFS= read -r key; do
    split "${key}"
    case "${BASE}" in [a-z]) has_mod alt || continue ;; *) continue ;; esac
    has_mod shift && upper "${BASE}" || printf '%s' "${BASE}"
    echo
  done | awk '!seen[$0]++' | sed "s/.*/'&'/" | paste -sd, - | sed 's/,/, /g')
  {
    echo "\" ${GEN_NOTE}"
    echo "\" Sourced by .vimrc (runtime keys.vim).  Functions live in autoload/vimide.vim."
    if [ -n "${alt_letters}" ]; then
      cat <<EOF

" Terminal vim sees Alt+letter as ESC + letter and does not decode it, so each one is
" declared first.  Alt+arrow needs no declaration (and set <M-Up>= is E518).
if !has('gui_running')
  for s:k in [${alt_letters}]
    execute 'set <M-' . s:k . ">=\\<Esc>" . s:k
  endfor
  unlet s:k
endif
EOF
    fi
    rows vim 'has("vim")' \
      '.group // "", .note // "", .key, (.vim.modes // ["n"] | join(" ")), (.vim.cmd // ""),
       (.vim.rhs // ""), ((.vim.silent // false) | tostring)' |
    while IFS="${US}" read -r group note key modes cmd rhs silent; do
      group_header '"' "${group}"
      [ -z "${note}" ] || echo "\" ${note}"
      k=$(vim_key "${key}")
      s=""; if [ "${silent}" = "true" ]; then s="<silent> "; fi
      for m in ${modes}; do
        case "${m}" in
          n) map=nnoremap; wrap=":${cmd}<CR>" ;;
          i) map=inoremap; wrap="<C-o>:${cmd}<CR>" ;;
          v) map=vnoremap; wrap="<Esc>:${cmd}<CR>" ;;
          *) die "vim: ${key}: unknown mode '${m}'" ;;
        esac
        [ -n "${cmd}" ] || wrap=${rhs}
        [ -n "${wrap}" ] || die "vim: ${key}: needs cmd or rhs"
        echo "${map} ${s}${k} ${wrap}"
      done
    done
  } > "${t}"
  finish "${t}" "${OUT_VIM}"
}

# --------------------------------------------------------------------------------------
# bash + zsh
# --------------------------------------------------------------------------------------

sequences_of() {
  n=$(yq -r ".sequences[\"$1\"] | length" "${YAML}")
  [ "${n}" -gt 0 ] || die "shell: '$1' has no entry under sequences:"
  yq -r ".sequences[\"$1\"][]" "${YAML}"
}

render_shell() {
  t="${TMPD}/shell"
  list="${TMPD}/shell.rows"
  rows shell 'has("zsh") or has("bash")' '.group // "", .note // "", .key, (.zsh // ""), (.bash // "")' > "${list}"
  {
    echo "# ${GEN_NOTE}"
    cat <<'EOF'
#
# Line-editing keys for both shells, in every byte form a terminal might send (the form
# depends on the emulator and on application-cursor mode).  Binding all of them removes
# the dependency on terminfo, on /etc/inputrc, and on any zsh framework.
# Rationale: docs/keyboard.md, "Navigation keys".

case $- in
  *i*) ;;
  *) return 0 2>/dev/null || true ;;
esac

if [ -n "$ZSH_VERSION" ]; then
  # Both keymaps, so a vi-mode zsh keeps these too.
  for _kmap in emacs viins; do
EOF
    LAST_GROUP=""
    while IFS="${US}" read -r group note key zw bw; do
      [ -n "${zw}" ] || continue
      group_header '    #' "${group}"
      [ -z "${note}" ] || echo "    # ${note}"
      sequences_of "${key}" | while IFS= read -r seq; do
        z=$(printf '%s' "${seq}" | sed -e 's/\\e/^[/g' -e 's/\\C-\(.\)/^\U\1/g')
        printf '    bindkey -M "$_kmap" %-10s %s\n' "'${z}'" "${zw}"
      done
    done < "${list}"
    cat <<'EOF'
  done
  unset _kmap

  # A word ends at every non-alphanumeric, as in bash; zsh's default swallows whole paths.
  WORDCHARS=''
fi

if [ -n "$BASH_VERSION" ]; then
EOF
    LAST_GROUP=""
    while IFS="${US}" read -r group note key zw bw; do
      [ -n "${bw}" ] || continue
      group_header '  #' "${group}"
      [ -z "${note}" ] || echo "  # ${note}"
      sequences_of "${key}" | while IFS= read -r seq; do
        printf "  bind '\"%s\": %s'\n" "${seq}" "${bw}"
      done
    done < "${list}"
    echo "fi"
  } > "${t}"
  finish "${t}" "${OUT_SHELL}"
}

# --------------------------------------------------------------------------------------
# labwc: replace only the block between the markers in rc.xml
# --------------------------------------------------------------------------------------

render_labwc() {
  [ -f "${OUT_LABWC}" ] || { log "skipped   .config/labwc/rc.xml (absent)"; return 0; }
  grep -qF "${LABWC_BEGIN}" "${OUT_LABWC}" && grep -qF "${LABWC_END}" "${OUT_LABWC}" \
    || die "labwc: rc.xml lacks the GENERATED markers inside <keyboard>"
  block="${TMPD}/labwc.block"
  LAST_GROUP=""
  rows compositor 'has("labwc")' \
    '.group // "", .note // "", .key, .labwc.action,
     ([.labwc | to_entries[] | select(.key != "action") | .key + "=" + (.value | tostring)] | join("'"${US}"'"))' |
  while IFS= read -r line; do
    group=${line%%"${US}"*}; line=${line#*"${US}"}
    note=${line%%"${US}"*};  line=${line#*"${US}"}
    key=${line%%"${US}"*};   line=${line#*"${US}"}
    act=${line%%"${US}"*}
    case "${line}" in *"${US}"*) attrs=${line#*"${US}"} ;; *) attrs="" ;; esac
    group_header '    <!--' "${group}" ' -->' '='
    [ -z "${note}" ] || echo "    <!-- $(xml_esc "${note}" | sed 's/--*/-/g') -->"
    a="name=\"$(xml_esc "${act}")\""
    old_ifs=$IFS; IFS=${US}
    for kv in ${attrs}; do a="${a} ${kv%%=*}=\"$(xml_esc "${kv#*=}")\""; done
    IFS=$old_ifs
    echo "    <keybind key=\"$(labwc_key "${key}")\">"
    echo "      <action ${a}/>"
    echo "    </keybind>"
  done > "${block}"
  t="${TMPD}/labwc"
  awk -v b="${LABWC_BEGIN}" -v e="${LABWC_END}" -v f="${block}" '
    index($0, b) { print; while ((getline l < f) > 0) print l; skip = 1; next }
    index($0, e) { skip = 0 }
    !skip' "${OUT_LABWC}" > "${t}"
  finish "${t}" "${OUT_LABWC}"
}

# --------------------------------------------------------------------------------------
# GNOME Shell + gnome-terminal: data lines for linux/terminal.sh
# --------------------------------------------------------------------------------------

GT_SCHEMA="org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/"

# gnome_value SCHEMA KEY UNBIND VALUE -> the gsettings value, quoted for sh.
# The Shell and wm schemas hold string arrays; gnome-terminal's hold one string.
gnome_value() {
  if [ -n "$4" ]; then printf '%s\n' "$4"; return; fi
  case "$1" in
    org.gnome.Terminal.Legacy.Keybindings*)
      if [ "$3" = "true" ]; then echo "\"'disabled'\""; else echo "\"'$(gtk_key "$2")'\""; fi ;;
    *)
      if [ "$3" = "true" ]; then echo '"[]"'; else echo "\"['$(gtk_key "$2")']\""; fi ;;
  esac
}

render_gnome() {
  t="${TMPD}/gnome"
  {
    echo "# ${GEN_NOTE}"
    echo "# Sourced by linux/terminal.sh, which defines gset() and gates it on a live GNOME"
    echo "# session.  gset SCHEMA KEY VALUE.  Order matters: outermost layer released first."
    echo
    echo "# gnome-terminal's keybinding schema is relocatable, so the path is part of its name."
    echo "GT=\"${GT_SCHEMA}\""
    LAST_GROUP=""
    rows compositor 'has("gnome")' \
      '.group // "", .key, .gnome.schema, .gnome.name, ((.gnome.unbind // false) | tostring), (.gnome.value // "")' |
    while IFS="${US}" read -r group key schema name unbind value; do
      group_header '#' "GNOME Shell: ${group}"
      echo "gset ${schema} ${name} $(gnome_value "${schema}" "${key}" "${unbind}" "${value}")"
    done
    LAST_GROUP=""
    rows terminal 'has("gnome-terminal")' \
      '.group // "", .key,
       ((.["gnome-terminal"] | select(tag == "!!map") | .schema) // "'"${GT_SCHEMA}"'"),
       ((.["gnome-terminal"] | select(tag == "!!map") | .name) // .["gnome-terminal"]),
       ((.["gnome-terminal"].unbind // false) | tostring), (.["gnome-terminal"].value // "")' |
    while IFS="${US}" read -r group key schema name unbind value; do
      group_header '#' "gnome-terminal: ${group}"
      s=${schema}; if [ "${s}" = "${GT_SCHEMA}" ]; then s='"$GT"'; fi
      echo "gset ${s} ${name} $(gnome_value "${schema}" "${key}" "${unbind}" "${value}")"
    done
  } > "${t}"
  finish "${t}" "${OUT_GNOME}"
}

# --------------------------------------------------------------------------------------
# docs/keyboard-cheatsheet.md: capture chain, per-layer tables, shadow report
# --------------------------------------------------------------------------------------

APPS='labwc|gnome|kitty|gnome-terminal|iterm2|tmux|zsh|bash|vim'

# One line per binding: layer, key, action, group, note, and the app list, where each app
# is name/unbind/pass/value -- enough for awk to decide who captures and who forwards.
all_rows() {
  for layer in $(yq -r '.layers[].id' "${YAML}"); do
    rows "${layer}" 'true' \
      "\"${layer}\", .key, .action, (.group // \"\"), (.note // \"\"),
       ([to_entries[] | select(.key | test(\"^(${APPS})\$\"))
         | .key + \"/\" + ((.value.unbind // false) | tostring) + \"/\" + (.value.pass // \"\")
                + \"/\" + (.value.value // \"\") + \"/\" + (.value.table // \"\")] | join(\" \"))"
  done
}

render_docs() {
  t="${TMPD}/docs"
  data="${TMPD}/all.rows"
  all_rows > "${data}"
  layers=$(yq -r '[.layers[].id] | join(" ")' "${YAML}")
  titles="${TMPD}/titles"
  yq -r ".layers[] | [.id, (.title // .id), (.where // \"\")] | join(\"${US}\")" "${YAML}" > "${titles}"
  {
    cat <<EOF
<!-- ${GEN_NOTE} -->

# Keyboard cheatsheet

Every binding in the dotfiles, generated from \`keys.yaml\`. Why each key
lives where it does is in \`keyboard.md\`; vim's own defaults are in \`vim-defaults.md\`.

**Capture order.** A keystroke goes \`os -> compositor -> terminal -> tmux -> shell | vim\`,
and the first layer that binds it wins. **Bold** marks that layer. \`→ vim\` / \`→ pager\`
means tmux forwards the key when the pane runs vim / a pager. "released" means the layer
explicitly lets the key through. ~~Struck~~ means an earlier layer takes the key first.

Keys are spelled \`ctrl alt shift super\`. Super is Cmd on macOS, and the key left of the
space bar on every machine; alt is Option.
EOF
    awk -F "${US}" -v layers="${layers}" -v titlefile="${titles}" '
      function cell_md(s) { gsub(/\|/, "\\|", s); return s }
      function tick(s) { return "`" s "`" }
      BEGIN {
        nl = split(layers, L, " ")
        for (i = 1; i <= nl; i++) idx[L[i]] = i
        while ((getline line < titlefile) > 0) {
          split(line, f, "\037"); title[f[1]] = f[2]; where[f[1]] = f[3]
        }
      }
      {
        layer = $1; key = $2; action = $3; group = $4; note = $5; apps = $6
        n = split(apps, A, " ")
        captures = 0; released = 0; pass = ""; names = ""; mode = ""
        for (j = 1; j <= n; j++) {
          split(A[j], p, "/")
          names = names (names ? ", " : "") p[1]
          if (p[2] == "true" || p[4] != "") { released = 1; continue }
          if (p[5] == "copy")   { mode = "copy-mode: "; continue }   # not the raw keystroke
          if (p[5] == "prefix") { mode = "after prefix: "; continue }
          captures = 1
          if (p[3] != "") pass = p[3]
        }
        if (n == 0) captures = 1                         # docs-only rows (os, mouse)
        if (mode != "") txt = mode action
        if (!(key in seen)) { seen[key] = 1; order[++nk] = key }
        c = layer SUBSEP key
        if (mode == "") txt = action
        if (pass != "") txt = "→ " pass ": " action
        if (!captures && released) txt = "released"
        if (!(c in cell)) cell[c] = txt
        else if (index("; " cell[c] "; ", "; " txt "; ") == 0) cell[c] = cell[c] "; " txt
        if (captures) { cap[c] = 1; if (pass != "") fwd[c] = pass }
        if ((layer SUBSEP key SUBSEP action) in dup) next
        dup[layer, key, action] = 1
        nrow[layer]++
        if (note == lastnote[layer]) note = ""; else lastnote[layer] = note   # ranges repeat it
        R[layer, nrow[layer]] = "| " tick(key) " | " cell_md(action) " | " cell_md(names) " | " cell_md(note) " |"
        gh[layer, nrow[layer]] = group
      }
      END {
        print "\n## Capture chain\n"
        hdr = "| key |"; sep = "| --- |"
        for (i = 1; i <= nl; i++) { hdr = hdr " " L[i] " |"; sep = sep " --- |" }
        print hdr; print sep
        nsh = 0
        for (k = 1; k <= nk; k++) {
          key = order[k]; row = "| " tick(key) " |"; taken = ""
          for (i = 1; i <= nl; i++) {
            c = L[i] SUBSEP key; v = (c in cell) ? cell_md(cell[c]) : ""
            if (v != "" && taken != "" && !(taken == "tmux" && fwd["tmux" SUBSEP key] == "vim" && L[i] == "vim")) {
              if (cap[c]) shadow[++nsh] = tick(key) ": " taken " (" cell[taken SUBSEP key] ") before " L[i] " (" cell[c] ")"
              v = "~~" v "~~"
            } else if (v != "" && cap[c] && taken == "") {
              v = "**" v "**"
            }
            if (cap[c] && taken == "") taken = L[i]
            row = row " " v " |"
          }
          print row
        }
        print "\n## Shadowed keys\n"
        if (nsh == 0) print "None: no layer binds a key that an earlier layer already takes."
        else {
          print "Bound in a later layer, but an earlier layer takes the key first. On a desktop"
          print "that does not run the earlier app (labwc vs GNOME, say) there is no conflict.\n"
          for (s = 1; s <= nsh; s++) print "- " shadow[s]
        }
        for (i = 1; i <= nl; i++) {
          l = L[i]
          print "\n## " title[l] "\n"
          if (where[l] != "") print "Rendered to / applied by: " where[l] "\n"
          print "| key | action | apps | note |"
          print "| --- | --- | --- | --- |"
          for (r = 1; r <= nrow[l]; r++) print R[l, r]
        }
      }' "${data}"
  } > "${t}"
  finish "${t}" "${OUT_DOCS}"
}

# --------------------------------------------------------------------------------------

check_keys
render_kitty
render_tmux
render_vim
render_shell
render_labwc
render_gnome
render_docs

if [ -n "${CHECK}" ] && [ "${STALE}" -ne 0 ]; then
  echo "render: generated files are stale; run scripts/keyboard/render.sh" >&2
  exit 1
fi
