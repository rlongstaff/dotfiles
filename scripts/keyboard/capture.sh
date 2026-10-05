#!/usr/bin/env bash
#
# Capture live key bindings into a keys.yaml-compatible snippet (inverse of render.sh).
#
#   scripts/keyboard/capture.sh [--all] [app...]
#
# apps: labwc gnome kitty gnome-terminal iterm2 tmux zsh bash vim   (default: all of them)
# --all keeps each app's built-in bindings; the default keeps only what you set.
# stdout is YAML; INFO and WARNING go to stderr.  Writes nothing: paste the output into
# keys.yaml by hand, then run render.sh.  The `os` layer has no live binding list and is
# not captured (a run over every app says so on stderr).
#
# bash 3.2 safe.  Requires mikefarah yq v4 for the bash and zsh readers (it maps byte
# sequences to key names) and for the optional output check; the other readers need only sh
# tools.

set -eu
set -f

: "${SCRIPT_DIR:=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}"
MODULE=capture
KEYS_YAML="${SCRIPT_DIR}/keys.yaml"
. "${SCRIPT_DIR}/scripts/lib.sh"
. "${SCRIPT_DIR}/scripts/keyboard/keys-lib.sh"

# keys-lib.sh: the from_* and validate functions assign plain (non-local) variables, among them
# MODS BASE p b m i s ms uni rest fl u inner low n un mods out l last.  Always call them inside
# $(...), and keep the readers' own variables to app-prefixed names.
APPS_ALL="labwc gnome kitty gnome-terminal iterm2 tmux zsh bash vim"
US=$(printf '\037')
ALL=0
REQ=""
PRISTINE=""
PRISTINE_SOCK=""
TMPD=$(mktemp -d)
# pristine_kill: stop the pristine tmux server (see cap_tmux) and remove its socket file, which
# tmux can leave behind and whose name is unique to this run.
pristine_kill() {
  [ -n "${PRISTINE}" ] || return 0
  tmux -L "${PRISTINE}" kill-server >/dev/null 2>&1 || :
  case "${PRISTINE_SOCK}" in */capture-pristine-*) rm -f "${PRISTINE_SOCK}" ;; esac
  PRISTINE=""
  return 0
}
# Runs on every way out.
cleanup() {
  pristine_kill
  rm -rf "${TMPD}"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP

for a in "$@"; do
  case "${a}" in
    --all) ALL=1 ;;
    -*) echo "usage: $0 [--all] [app...]" >&2; exit 2 ;;
    *) case " ${APPS_ALL} " in
         *" ${a} "*) REQ="${REQ} ${a}" ;;
         *) echo "capture: unknown app '${a}' (known: ${APPS_ALL})" >&2; exit 2 ;;
       esac ;;
  esac
done
ALLAPPS=0
[ -n "${REQ}" ] || { REQ=${APPS_ALL}; ALLAPPS=1; }

absent() { echo "capture: INFO $1: not detected ($2), nothing captured" >&2; }
note()   { echo "capture: $*" >&2; }

# yq_q STR -> YAML scalar, safe inside a flow mapping.  Plain when it is safe, else
# single-quoted ('' escapes ').
yq_q() {
  yqlc=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "${yqlc}" in
    true|false|null|yes|no|on|off|y|n) yqquote=1 ;;
    *) yqquote=0 ;;
  esac
  case "$1" in
    ""|*[!A-Za-z0-9_+./@=\ -]*|[-0-9@.\ ]*|*\ ) yqquote=1 ;;
  esac
  if [ "${yqquote}" -eq 1 ]; then
    printf "'%s'\n" "$(printf '%s' "$1" | sed "s/'/''/g")"
  else
    printf '%s\n' "$1"
  fi
}

# rec KEY APP ACTION YAMLVALUE LAYER -> one record.  KEY must be canonical; an invalid one
# becomes an UNMAPPED comment instead.
rec() {
  if why=$(validate "$1"); then
    printf '%s%s%s%s%s%s%s\n' "$1" "${US}" "$2" "${US}" "$3" "${US}" "$4" >> "${TMPD}/layer.$5"
  else
    printf '# UNMAPPED %s: %s (%s)\n' "$2" "$1" "${why}" >> "${TMPD}/layer.$5.unmapped"
  fi
  return 0
}
unmapped() { printf '# UNMAPPED %s: %s\n' "$1" "$2" >> "${TMPD}/layer.$3.unmapped"; return 0; }

# emit_layer ID TITLE -> a layer block.  Records with the same key merge into one binding,
# one field per app.  A second record for an app already on that key (same key in another
# tmux table, say) starts a further binding; an exact duplicate is dropped.
emit_layer() {
  f="${TMPD}/layer.$1"
  [ -s "${f}" ] || [ -s "${f}.unmapped" ] || return 0
  printf '  - id: %s\n    title: %s\n    bindings:\n' "$1" "$2"
  if [ -s "${f}" ]; then
    awk -F "${US}" '
      {
        k = $1; app = $2; v = $4
        if (k SUBSEP app SUBSEP v in dup) next
        dup[k SUBSEP app SUBSEP v] = 1
        if (!(k in nb)) { nb[k] = 0; korder[++nk] = k }
        b = 0
        for (j = 1; j <= nb[k]; j++) if (!((k, j, app) in has)) { b = j; break }
        if (!b) {
          b = ++nb[k]; id = ++total; gid[k, b] = id
          bkey[id] = k; bact[id] = $3; border[id] = ""
          ord[++no] = id
        }
        id = gid[k, b]; has[k, b, app] = 1
        body[id] = body[id] sprintf("        %s: %s\n", app, v)
      }
      END {
        for (i = 1; i <= no; i++) {
          id = ord[i]
          printf "      - key: %s\n        action: %s\n%s", Q(bkey[id]), Q(bact[id]), body[id]
        }
      }
      function Q(s) {
        if (s ~ /^[A-Za-z]$|^[A-Za-z][A-Za-z0-9_+ .\/=-]*[A-Za-z0-9_+.\/=-]$/ && tolower(s) !~ /^(true|false|null|yes|no|on|off|y|n)$/) return s
        gsub(/\047/, "\047\047", s); return "\047" s "\047"
      }' "${f}"
  fi
  if [ -s "${f}.unmapped" ]; then sed 's/^/      /' "${f}.unmapped"; fi
  return 0
}

# --------------------------------------------------------------------------------------
# readers: one per app.  Contract: print nothing to stdout; call rec/unmapped/absent;
# always return 0.
# --------------------------------------------------------------------------------------

cap_tmux() {
  tmsock=${CAPTURE_TMUX_SOCKET:-}
  if [ -n "${tmsock}" ]; then tm="tmux -L ${tmsock}"; else tm=tmux; fi
  have tmux || { absent tmux "tmux not installed"; return 0; }
  # list-keys itself starts a server (and loads ~/.tmux.conf), so probe with a command that
  # does not.
  ${tm} list-sessions >/dev/null 2>&1 || { absent tmux "no running tmux server"; return 0; }
  ${tm} list-keys > "${TMPD}/tmux.live" 2>/dev/null \
    || { absent tmux "list-keys failed"; return 0; }
  if [ "${ALL}" -eq 0 ]; then
    # The built-in bindings come from a throwaway server with no config.  Its socket is unique
    # to this run (concurrent runs must not share or kill each other's), and its one session
    # runs an inert command so no interactive shell starts; cleanup() kills it on every exit.
    : > "${TMPD}/tmux.base"
    PRISTINE="capture-pristine-$$"
    tmux -L "${PRISTINE}" -f /dev/null new-session -d -s base 'sleep 30' >/dev/null 2>&1 \
      && PRISTINE_SOCK=$(tmux -L "${PRISTINE}" display-message -p '#{socket_path}' 2>/dev/null) \
      && tmux -L "${PRISTINE}" list-keys > "${TMPD}/tmux.base" 2>/dev/null || :
    pristine_kill
    if [ -s "${TMPD}/tmux.base" ]; then
      # list-keys pads columns by the widest key, so compare with runs of spaces collapsed.
      # The first file is told apart by name: with an empty first file NR == FNR would hold
      # for the second file too.
      awk 'FILENAME == ARGV[1] { gsub(/ +/, " "); base[$0] = 1; next }
           { l = $0; gsub(/ +/, " ", l); if (!(l in base)) print }' \
        "${TMPD}/tmux.base" "${TMPD}/tmux.live" > "${TMPD}/tmux.user"
    else
      note "WARNING tmux: could not read pristine defaults; showing all bindings"
      cp "${TMPD}/tmux.live" "${TMPD}/tmux.user"
    fi
  else
    cp "${TMPD}/tmux.live" "${TMPD}/tmux.user"
  fi
  # bind-key [-r] -T TABLE KEY CMD...  (read keeps the spacing inside CMD).  The -r (repeat)
  # flag is read and dropped: keys.yaml has no way to say a binding repeats.
  while IFS= read -r tmline; do
    [ -n "${tmline}" ] || continue
    tmrest=""
    read -r tmverb tmw1 tmw2 tmw3 tmw4 tmrest <<EOL || :
${tmline}
EOL
    [ "${tmverb}" = bind-key ] || continue
    if [ "${tmw1}" = -r ]; then
      tmtab=${tmw3}; tmkey=${tmw4}; tmcmd=${tmrest}
      [ "${tmw2}" = -T ] || continue
    else
      tmtab=${tmw2}; tmkey=${tmw3}; tmcmd="${tmw4} ${tmrest}"
      [ "${tmw1}" = -T ] || continue
    fi
    tmcmd=${tmcmd# }; tmcmd=${tmcmd% }
    case "${tmtab}" in
      root) tmtb="" ;; prefix) tmtb="table: prefix, " ;; copy-mode-vi) tmtb="table: copy, " ;;
      off) tmtb="table: off, " ;;
      *) unmapped tmux "${tmtab} ${tmkey}" tmux; continue ;;
    esac
    # list-keys double-quotes keys it would otherwise have to escape ("M-#", "M-%").
    case "${tmkey}" in \"?*\") tmkey=${tmkey#\"}; tmkey=${tmkey%\"} ;; esac
    tmkc=$(from_tmux "${tmkey}") || { unmapped tmux "${tmtab} ${tmkey}" tmux; continue; }
    tmpass=""
    case "${tmcmd}" in
      'if-shell "ps -o state='*'send-keys '*) tmpass="pass: vim, " ;;
      'if-shell -F "#{||:#{alternate_on}'*'send-keys '*) tmpass="pass: pager, " ;;
    esac
    if [ -n "${tmpass}" ]; then
      tmcmd=$(printf '%s' "${tmcmd}" | sed -e 's/.*" "send-keys [^"]*" "//' -e 's/"$//')
    fi
    rec "${tmkc}" tmux "${tmcmd%% *}" "{${tmtb}${tmpass}cmd: $(yq_q "${tmcmd}")}" tmux
  done < "${TMPD}/tmux.user"
  return 0
}

# vim: dump every map with its defining script (:verbose), keep the ones set from the user's
# own files.  Listing format (verified on vim 9.1): mode letter, two spaces, lhs padded to 12
# columns (lhs + one space when longer), a flag column (* noremap, & script-local), a flag
# column (@ buffer-local), then the rhs; a tab-indented "Last set from <file> line N" follows.
# The listing does not show <silent>, so `silent` cannot be recovered and is left out.
cap_vim() {
  have vim || { absent vim "vim not installed"; return 0; }
  # `vim -es` does not read the user's vimrc on its own: pass it with -u.
  vimargs=${CAPTURE_VIM_ARGS:-}
  vxdg=${XDG_CONFIG_HOME:-${HOME}/.config}
  if [ -z "${vimargs}" ]; then
    for vrc in "${HOME}/.vimrc" "${HOME}/.vim/vimrc" "${vxdg}/vim/vimrc"; do
      if [ -f "${vrc}" ]; then vimargs="-u ${vrc}"; break; fi
    done
    [ -n "${vimargs}" ] || { absent vim "no vimrc found"; return 0; }
  fi
  # shellcheck disable=SC2086
  vim ${vimargs} -i NONE -es \
    -c "redir! > ${TMPD}/vim.maps | silent verbose map | silent verbose map! | redir END" -c q \
    </dev/null >/dev/null 2>&1 || :
  [ -s "${TMPD}/vim.maps" ] || { absent vim "vim produced no mapping listing"; return 0; }
  # User-only: drop maps defined by plugin directories and vim's runtime, anchored to those
  # locations so a vimrc that merely lives under a directory named pack/vendor is kept.
  awk -v all="${ALL}" -v US="${US}" -v home="${HOME}" -v xdg="${vxdg}" -v vrt="${VIMRUNTIME:-}" '
    function plugin(f,   d) {
      if (substr(f, 1, 2) == "~/") f = home substr(f, 2)
      if (f ~ /^\/usr\/(local\/)?share\/vim\// || f ~ /\/share\/vim\/vim[0-9]+\//) return 1
      if (vrt != "" && index(f, vrt "/") == 1) return 1
      for (d = 1; d <= 3; d++) {
        split("pack bundle plugged", dn, " ")
        if (index(f, home "/.vim/" dn[d] "/") == 1 || index(f, xdg "/vim/" dn[d] "/") == 1) return 1
      }
      if (f ~ /\/vendor\/[^\/]+\/(plugin|autoload|ftplugin|syntax|indent)\//) return 1
      if (f ~ /\/\.vim\/bundle\/[^\/]+\//) return 1
      return 0
    }
    /^[nvxsoilc! ]  / {
      mode = substr($0, 1, 1); rest = substr($0, 4)
      lhs = rest; sub(/ .*/, "", lhs)
      off = length(lhs) < 12 ? 12 : length(lhs) + 1
      rhs = substr(rest, off + 3)
      held = mode US lhs US rhs; next
    }
    /^\tLast set from / {
      f = $0; sub(/^\tLast set from /, "", f); sub(/ line [0-9]+$/, "", f)
      if (held != "" && (all == 1 || !plugin(f))) print held
      held = ""; next
    }
    { held = "" }' "${TMPD}/vim.maps" > "${TMPD}/vim.user"
  [ -s "${TMPD}/vim.user" ] \
    || note "INFO vim: no user-defined mappings found (use --all to include plugin and runtime maps)"
  : > "${TMPD}/vim.recs"
  while IFS="${US}" read -r vmode vlhs vrhs; do
    case "${vlhs}" in '<Plug>'*|'<SNR>'*) continue ;; esac
    # :map shows <C-a> as <C-A>; only an explicit S- means shift, so lowercase the letter.
    case "${vlhs}" in
      *'S-'*) ;;
      '<'*'C-'[A-Z]'>') vbase=${vlhs%>}; vlhs="${vbase%?}$(printf '%s' "${vbase#"${vbase%?}"}" | tr '[:upper:]' '[:lower:]')>" ;;
    esac
    vkey=$(from_vim "${vlhs}") || { unmapped vim "${vlhs}" vim; continue; }
    case "${vmode}" in
      n) vms=n ;; i|'!') vms=i ;; v|x) vms=v ;; ' ') vms="n v" ;;
      *) unmapped vim "${vmode} ${vlhs}" vim; continue ;;
    esac
    for vm in ${vms}; do
      # Undo render.sh's per-mode wrapper so a cmd binding round-trips as `cmd:`.
      # (vim lists <C-o> as <C-O>, so match on a lowercased copy and strip by length.)
      vcmd=""; vlow=$(printf '%s' "${vrhs}" | tr '[:upper:]' '[:lower:]')
      case "${vm}:${vlow}" in
        n:':'*'<cr>') vcmd=${vrhs#?} ;;
        i:'<c-o>:'*'<cr>') vcmd=${vrhs#??????} ;;
        v:'<esc>:'*'<cr>') vcmd=${vrhs#??????} ;;
        v:':'*'<cr>') vcmd=${vrhs#?} ;;
      esac
      vcmd=${vcmd%????}
      case "${vcmd}" in *'<CR>'*|*'<cr>'*) vcmd="" ;; esac
      if [ -n "${vcmd}" ]; then vtag="c${vcmd}"; else vtag="r${vrhs}"; fi
      printf '%s%s%s%s%s\n' "${vkey}" "${US}" "${vm}" "${US}" "${vtag}" >> "${TMPD}/vim.recs"
    done
  done < "${TMPD}/vim.user"
  [ -s "${TMPD}/vim.recs" ] || return 0
  # One binding per key+body, modes merged and ordered n,i,v.
  awk -F "${US}" -v US="${US}" '
    { g = $1 SUBSEP $3; if (!(g in seen)) { seen[g] = 1; order[++cnt] = g; kk[g] = $1; tt[g] = $3 }
      has[g, $2] = 1 }
    END { for (j = 1; j <= cnt; j++) { g = order[j]; ms = ""
            if (has[g, "n"]) ms = ms "n"
            if (has[g, "i"]) ms = ms (ms == "" ? "" : ",") "i"
            if (has[g, "v"]) ms = ms (ms == "" ? "" : ",") "v"
            print kk[g] US ms US tt[g] } }' "${TMPD}/vim.recs" > "${TMPD}/vim.groups"
  while IFS="${US}" read -r vkey vmodes vtag; do
    if [ "${vtag%"${vtag#?}"}" = c ]; then
      vbody="cmd: $(yq_q "${vtag#?}")"
    else
      vbody="rhs: $(yq_q "${vtag#?}")"
    fi
    rec "${vkey}" vim "${vtag#?}" "{modes: [${vmodes}], ${vbody}}" vim
  done < "${TMPD}/vim.groups"
  return 0
}

# kitty: the effective keymap of the user's kitty.conf (KITTY_CONFIG_DIRECTORY or
# ~/.config/kitty) minus kitty's built-in one.  load_config() with no path reads no file, so
# the config file is passed explicitly.  The script runs from a file under the temp dir (no
# quoting hazards) with its own globals dict, since +runpy's exec scope hides top-level defs.
# A `map KEY` with no action reads back as an empty definition: it is reported as no_op.
cap_kitty() {
  have kitty || { absent kitty "kitty not installed"; return 0; }
  cat > "${TMPD}/kitty.py" <<'PYEOF2'
import os
import sys
from kitty.config import load_config
from kitty.constants import config_dir
from kitty import key_encoding as ke

names = ke.functional_key_number_to_name_map


def label(t):
    """(text, ok): ok is False for a key that has no name in keys.yaml's spelling."""
    mods = [n for b, n in ((4, "ctrl"), (2, "alt"), (1, "shift"), (8, "super")) if t.mods & b]
    k = t.key
    if k in names:
        base, ok = names[k].lower(), True
    elif 32 < k < 127:
        base, ok = chr(k).lower(), True
    else:
        base, ok = "U+%04x" % k, False
    return "+".join(mods + [base]), ok


def keymap(o):
    """label -> (mappable, action).  A key sequence is never mappable: keys.yaml binds one key."""
    d = {}
    for ks, defs in o.keyboard_modes[""].keymap.items():
        for x in defs:
            parts = [label(x.trigger)]
            seq = bool(x.is_sequence or x.rest)
            if seq:
                parts += [label(r) for r in x.rest]
            text = ">".join(p[0] for p in parts)
            d[text] = (not seq and all(p[1] for p in parts), x.definition)
    return d


eff = keymap(load_config(os.path.join(config_dir, "kitty.conf")))
base = keymap(load_config("/dev/null"))
for k, (good, v) in eff.items():
    if sys.argv[1] == "1" or base.get(k) != (good, v):
        print(("K" if good else "U") + "\x1f" + k + "\x1f" + (v or "no_op"))
PYEOF2
  kitty +runpy "import sys; sys.argv=['k','${ALL}']; exec(open('${TMPD}/kitty.py').read(), {'__name__': 'kitty_dump'})" \
    > "${TMPD}/kitty.out" 2> "${TMPD}/kitty.err" \
    </dev/null || { absent kitty "kitty +runpy failed: $(head -c 120 "${TMPD}/kitty.err" | tail -1)"; return 0; }
  while IFS="${US}" read -r ktype kkey kact; do
    if [ "${ktype}" != K ]; then unmapped kitty "${kkey} ${kact}" terminal; continue; fi
    kc=$(from_kitty "${kkey}") || { unmapped kitty "${kkey} ${kact}" terminal; continue; }
    rec "${kc}" kitty "${kact}" "$(yq_q "${kact}")" terminal
  done < "${TMPD}/kitty.out"
  return 0
}

# shell line editing.  The byte forms a key sends are listed under keys.yaml's `sequences:`;
# a live binding is mapped back to its key through that table.  Throwaway shells are
# interactive, so they load the user's rc files, which would autostart tmux: every one runs
# with DOTFILES_TMUX_AUTOSTART=0.

# seq_map_init: one `SEQ<US>KEY` line per entry of `sequences:`, built once.
seq_map_init() {
  [ -f "${TMPD}/seq.map" ] && return 0
  if ! have yq; then
    note "WARNING shell: yq not found, byte sequences cannot be mapped to key names"
    : > "${TMPD}/seq.map"
    return 0
  fi
  yq -r '.sequences | to_entries[] | .key as $k | .value[] | . + "'"${US}"'" + $k' "${KEYS_YAML}" \
    > "${TMPD}/seq.map" 2>/dev/null || : > "${TMPD}/seq.map"
  return 0
}
# seq_to_key SEQ -> canonical key whose `sequences:` list holds exactly SEQ (status 1: none).
# ENVIRON, not awk -v: -v would interpret the backslashes.
seq_to_key() {
  seq_map_init
  SEQ_Q="$1" awk -F "${US}" '$1 == ENVIRON["SEQ_Q"] { print $2; found = 1; exit } END { exit !found }' \
    "${TMPD}/seq.map"
}

# shell_user LIVE BASE OUT: the lines of LIVE that BASE lacks (all of LIVE with --all).
shell_user() {
  if [ "${ALL}" -eq 0 ]; then grep -vxFf "$2" "$1" > "$3" || :; else cp "$1" "$3"; fi
}

# shell_records APP FILE: FILE holds `SEQ<US>FN` (SEQ in table spelling); emit the records.
shell_records() {
  shn=0
  while IFS="${US}" read -r shseq shfn; do
    [ -n "${shseq}" ] || continue
    shn=$((shn + 1))
    shkey=$(seq_to_key "${shseq}") || { unmapped "$1" "${shseq} ${shfn}" shell; continue; }
    rec "${shkey}" "$1" "${shfn}" "$(yq_q "${shfn}")" shell
  done < "$2"
  [ "${shn}" -gt 0 ] \
    || note "INFO $1: no user-defined bindings found (use --all to include built-in bindings)"
  return 0
}

# bind -p prints `"SEQ": function`, and one line per readline alias of a function (vi-bword,
# vi-bWord and vi-backward-bigword are one function), so keep the last name per sequence.
# User-only mode reads just the user's own files: ~/.bashrc (not /etc/bash.bashrc) and
# INPUTRC or ~/.inputrc (not /etc/inputrc).
cap_bash() {
  have bash || { absent bash "bash not installed"; return 0; }
  bashrc=/dev/null; [ -f "${HOME}/.bashrc" ] && bashrc="${HOME}/.bashrc"
  inputrc=${INPUTRC:-}
  if [ -z "${inputrc}" ]; then
    if [ -f "${HOME}/.inputrc" ]; then inputrc="${HOME}/.inputrc"; else inputrc=/dev/null; fi
  fi
  if [ "${ALL}" -eq 1 ]; then
    DOTFILES_TMUX_AUTOSTART=0 bash -ic 'bind -p' </dev/null 2>/dev/null > "${TMPD}/bash.raw" || :
  else
    DOTFILES_TMUX_AUTOSTART=0 INPUTRC="${inputrc}" bash --noprofile --rcfile "${bashrc}" -ic 'bind -p' \
      </dev/null 2>/dev/null > "${TMPD}/bash.raw" || :
  fi
  grep '^"' "${TMPD}/bash.raw" > "${TMPD}/bash.live" || :
  [ -s "${TMPD}/bash.live" ] || { absent bash "bash -ic 'bind -p' printed no bindings"; return 0; }
  : > "${TMPD}/bash.base"
  DOTFILES_TMUX_AUTOSTART=0 INPUTRC=/dev/null bash --noprofile --norc -ic 'bind -p' </dev/null 2>/dev/null \
    | grep '^"' > "${TMPD}/bash.base" || :
  shell_user "${TMPD}/bash.live" "${TMPD}/bash.base" "${TMPD}/bash.user"
  awk -v US="${US}" '
    { i = 0; s = $0
      while ((j = index(substr(s, i + 1), "\": ")) > 0) i += j      # last `": `
      if (i < 2) next
      seq = substr(s, 2, i - 2); fn = substr(s, i + 3)
      if (!(seq in at)) { at[seq] = ++n; ord[n] = seq }
      f[seq] = fn }
    END { for (k = 1; k <= n; k++) print ord[k] US f[ord[k]] }' "${TMPD}/bash.user" > "${TMPD}/bash.recs"
  shell_records bash "${TMPD}/bash.recs"
}

# Bare bindkey lists the main keymap (viins when EDITOR is vi, else emacs), the one in use.
# bindkey prints `"SEQ" widget` with ^X for control keys and ^[ for escape; a `"a"-"b"` line
# is a range and is skipped.  Rewrite SEQ in the table's spelling: ^[ -> \e, ^X -> \C-x.
cap_zsh() {
  have zsh || { absent zsh "zsh not installed"; return 0; }
  if [ "${ALL}" -eq 1 ]; then zshflags="-i"; else zshflags="-d -i"; fi   # -d: no /etc/zsh rc files
  DOTFILES_TMUX_AUTOSTART=0 zsh ${zshflags} -c bindkey </dev/null 2>/dev/null > "${TMPD}/zsh.raw" || :
  grep '^"' "${TMPD}/zsh.raw" > "${TMPD}/zsh.live" || :
  [ -s "${TMPD}/zsh.live" ] || { absent zsh "zsh -ic 'bindkey' printed no bindings"; return 0; }
  : > "${TMPD}/zsh.base"
  DOTFILES_TMUX_AUTOSTART=0 zsh -f -i -c bindkey </dev/null 2>/dev/null \
    | grep '^"' > "${TMPD}/zsh.base" || :
  shell_user "${TMPD}/zsh.live" "${TMPD}/zsh.base" "${TMPD}/zsh.user"
  # bindkey prints runs of keys as `"^E"-"^F" self-insert`.  When the user's rc rebinds one key
  # of such a run the remainder is listed on its own (`"^F" self-insert`) and so differs from
  # the baseline line; it is not a binding the user made.  Drop self-insert in user-only mode.
  if [ "${ALL}" -eq 0 ]; then
    grep -v '^".*" self-insert$' "${TMPD}/zsh.user" > "${TMPD}/zsh.user2" || :
    mv "${TMPD}/zsh.user2" "${TMPD}/zsh.user"
  fi
  awk -v US="${US}" '
    { s = $0; i = 2
      while (i <= length(s)) {                       # first unescaped `" `
        c = substr(s, i, 1)
        if (c == "\\") { i += 2; continue }
        if (c == "\"") break
        i++
      }
      if (i > length(s) || substr(s, i, 2) != "\" ") next   # range ("a"-"b") or malformed
      seq = substr(s, 2, i - 2); fn = substr(s, i + 2)
      out = ""
      for (k = 1; k <= length(seq); k++) {
        c = substr(seq, k, 1)
        if (c == "\\") { out = out c substr(seq, k + 1, 1); k++ }
        else if (c == "^" && k < length(seq)) {
          k++; c = substr(seq, k, 1)
          if (c == "[") out = out "\\e"
          else out = out "\\C-" tolower(c)
        } else out = out c
      }
      print out US fn }' "${TMPD}/zsh.user" > "${TMPD}/zsh.recs"
  shell_records zsh "${TMPD}/zsh.recs"
}

# labwc: the user's rc.xml (CAPTURE_LABWC_RC, else $XDG_CONFIG_HOME/labwc/rc.xml, else
# ~/.config/labwc/rc.xml).  The block render.sh writes between the GENERATED markers is the
# repo's own, so it is skipped unless --all.  A plain awk pass rather than yq's XML mode: a
# keybind may be on one line or spread over several, and attribute handling there is brittle.
# Comments are stripped, then every <keybind ...> / <action ...> / </keybind> tag is read in
# order; attribute values are entity-decoded.  Only the first <action> of a keybind is kept:
# the rest (and the actions nested in an action) are reported as UNMAPPED, never dropped.
# Output lines: K<US>key<US>name<US>attr=val<US>...; X<US>key<US>name (extra action);
# A<US>key<US>attr (extra keybind attribute); C<US>key<US>name (action with child elements).
cap_labwc() {
  lwrc=${CAPTURE_LABWC_RC:-${XDG_CONFIG_HOME:-${HOME}/.config}/labwc/rc.xml}
  [ -f "${lwrc}" ] || { absent labwc "no rc.xml at ${lwrc}"; return 0; }
  awk -v all="${ALL}" -v US="${US}" '
    function dec(v) {
      gsub(/&lt;/, "<", v); gsub(/&gt;/, ">", v); gsub(/&quot;/, "\"", v)
      gsub(/&apos;/, "\047", v); gsub(/&amp;/, "\\&", v); return v
    }
    # attr(tag, name): decoded value of attribute NAME in TAG, "" when absent.
    function attrs(tag,   a, k, v, r) {
      sub(/^<[A-Za-z]+/, "", tag); A_N = 0
      while (match(tag, /[A-Za-z_:][-A-Za-z0-9_:.]*=("[^"]*"|\047[^\047]*\047)/)) {
        a = substr(tag, RSTART, RLENGTH); tag = substr(tag, RSTART + RLENGTH)
        k = a; sub(/=.*/, "", k); v = substr(a, length(k) + 3); v = substr(v, 1, length(v) - 1)
        A_K[++A_N] = k; A_V[A_N] = dec(v)
      }
    }
    /BEGIN GENERATED/ { skip = !all; next }
    /END GENERATED/   { skip = 0; next }
    !skip { t = t " " $0 }
    END {
      while ((i = index(t, "<!--")) > 0) {
        j = index(substr(t, i), "-->")
        t = substr(t, 1, i - 1) " " (j > 0 ? substr(t, i + j + 2) : "")
      }
      key = ""; nact = 0
      while (match(t, /<(keybind|action)[ \t]([^>"\047]|"[^"]*"|\047[^\047]*\047)*>|<\/keybind>/)) {
        tag = substr(t, RSTART, RLENGTH); t = substr(t, RSTART + RLENGTH)
        if (tag == "</keybind>") { key = ""; continue }
        attrs(tag)
        if (tag ~ /^<keybind/) {
          key = ""; nact = 0
          for (n = 1; n <= A_N; n++) if (A_K[n] == "key") key = A_V[n]
          if (tag ~ /\/>$/) key = ""
          if (key != "") for (n = 1; n <= A_N; n++) if (A_K[n] != "key") print "A" US key US A_K[n]
          continue
        }
        if (key == "") continue
        name = ""
        for (n = 1; n <= A_N; n++) if (A_K[n] == "name") name = A_V[n]
        if (++nact > 1) { print "X" US key US name; continue }
        if (tag !~ /\/>$/ && t !~ /^[ \t]*<\/action>/) print "C" US key US name
        line = "K" US key US name
        for (n = 1; n <= A_N; n++) if (A_K[n] != "name") line = line US A_K[n] "=" A_V[n]
        print line
      }
    }' "${lwrc}" > "${TMPD}/labwc.out" 2>/dev/null || { absent labwc "rc.xml not parseable"; return 0; }
  lwn=0
  while IFS="${US}" read -r lwtype lwk lwname lwrest; do
    case "${lwtype}" in
      X) unmapped labwc "${lwk} extra action ${lwname}" compositor; continue ;;
      A) unmapped labwc "${lwk} attribute ${lwname} (not captured)" compositor; continue ;;
      C) unmapped labwc "${lwk} child elements of action ${lwname} (not captured)" compositor; continue ;;
    esac
    lwn=$((lwn + 1))
    lwkey=$(from_labwc "${lwk}") || { unmapped labwc "${lwk}" compositor; continue; }
    lwv="{action: $(yq_q "${lwname}")"
    lwold=${IFS}; IFS=${US}
    for lwkv in ${lwrest}; do lwv="${lwv}, $(yq_q "${lwkv%%=*}"): $(yq_q "${lwkv#*=}")"; done
    IFS=${lwold}
    rec "${lwkey}" labwc "${lwname}" "${lwv}}" compositor
  done < "${TMPD}/labwc.out"
  [ "${lwn}" -gt 0 ] || [ "${ALL}" -eq 1 ] \
    || note "INFO labwc: no user-defined bindings found (use --all to include the generated block)"
  return 0
}

# gnome: every accelerator in the GNOME Shell / mutter / settings-daemon key schemas.
# gsettings has no is-default query, so user-only mode diffs the live listing against the
# schema defaults, which GSETTINGS_BACKEND=memory shows (that backend ignores the user's
# dconf and is private to the process: nothing is written).  A value the user emptied has no
# key to name and becomes an UNMAPPED comment (user-only mode).  Test seams: CAPTURE_GNOME_LIVE
# and CAPTURE_GNOME_DEFAULT name files holding `gsettings list-recursively` text.
GS_SCHEMAS="org.gnome.desktop.wm.keybindings org.gnome.shell.keybindings org.gnome.settings-daemon.plugins.media-keys"
cap_gnome() {
  gnlive=${CAPTURE_GNOME_LIVE:-}; gndef=${CAPTURE_GNOME_DEFAULT:-}
  if [ -z "${gnlive}" ]; then
    have gsettings || { absent gnome "gsettings not installed"; return 0; }
    gsettings list-schemas 2>/dev/null | grep -qx 'org.gnome.shell.keybindings' \
      || { absent gnome "no GNOME Shell schemas"; return 0; }
  fi
  : > "${TMPD}/gnome.out"
  for gns in ${GS_SCHEMAS}; do
    if [ -n "${gnlive}" ]; then
      awk -v s="${gns}" '$1 == s' "${gnlive}" > "${TMPD}/gnome.live"
      if [ -n "${gndef}" ]; then awk -v s="${gns}" '$1 == s' "${gndef}" > "${TMPD}/gnome.def"
      else : > "${TMPD}/gnome.def"; fi
    else
      gsettings list-recursively "${gns}" > "${TMPD}/gnome.live" 2>/dev/null || : > "${TMPD}/gnome.live"
      GSETTINGS_BACKEND=memory gsettings list-recursively "${gns}" > "${TMPD}/gnome.def" 2>/dev/null \
        || : > "${TMPD}/gnome.def"
    fi
    if [ "${ALL}" -eq 1 ]; then cat "${TMPD}/gnome.live" >> "${TMPD}/gnome.out"
    else grep -vxFf "${TMPD}/gnome.def" "${TMPD}/gnome.live" >> "${TMPD}/gnome.out" || :; fi
  done
  gnn=0
  while read -r gns gnname gnval; do
    case "${gnval}" in '['*|'@as ['*) ;; *) continue ;; esac
    gnn=$((gnn + 1))
    gnaccs=$(printf '%s\n' "${gnval}" | grep -o "'[^']*'" | tr -d "'" || :)
    if [ -z "${gnaccs}" ]; then
      [ "${ALL}" -eq 1 ] || unmapped gnome "${gns} ${gnname} (unbound)" compositor
      continue
    fi
    for gnacc in ${gnaccs}; do
      gnkey=$(from_gtk "${gnacc}") || { unmapped gnome "${gns} ${gnname} ${gnacc}" compositor; continue; }
      rec "${gnkey}" gnome "${gnname}" "{schema: ${gns}, name: $(yq_q "${gnname}")}" compositor
    done
  done < "${TMPD}/gnome.out"
  [ "${gnn}" -gt 0 ] || [ "${ALL}" -eq 1 ] \
    || note "INFO gnome: no user-defined bindings found (use --all to include defaults)"
  return 0
}

# gnome-terminal: dconf holds only what the user set, so user-only mode is that dump minus
# values equal to the schema default (read through the memory backend, as above).  --all
# starts from the defaults and lets the user's value replace the default of the same name.
# A `disabled` value has no key: UNMAPPED (unbound), user-only mode.  Test seams:
# CAPTURE_GT_DUMP (dconf dump text) and CAPTURE_GT_DEFAULT (list-recursively text).
cap_gnome_terminal() {
  gtpath=/org/gnome/terminal/legacy/keybindings/
  gtschema="org.gnome.Terminal.Legacy.Keybindings"
  if [ -n "${CAPTURE_GT_DUMP:-}" ]; then cp "${CAPTURE_GT_DUMP}" "${TMPD}/gt.dump" 2>/dev/null || : > "${TMPD}/gt.dump"
  else
    have dconf || { absent gnome-terminal "dconf not installed"; return 0; }
    dconf dump "${gtpath}" > "${TMPD}/gt.dump" 2>/dev/null || : > "${TMPD}/gt.dump"
  fi
  if [ -n "${CAPTURE_GT_DEFAULT:-}" ]; then cp "${CAPTURE_GT_DEFAULT}" "${TMPD}/gt.defraw" 2>/dev/null || : > "${TMPD}/gt.defraw"
  elif have gsettings; then
    GSETTINGS_BACKEND=memory gsettings list-recursively "${gtschema}:${gtpath}" > "${TMPD}/gt.defraw" 2>/dev/null \
      || : > "${TMPD}/gt.defraw"
  else : > "${TMPD}/gt.defraw"; fi
  if [ ! -s "${TMPD}/gt.dump" ] && [ ! -s "${TMPD}/gt.defraw" ]; then
    absent gnome-terminal "no gnome-terminal keybinding schema or settings"; return 0
  fi
  sed -n "s/^[^ ]* \([a-z0-9-]*\) '\(.*\)'\$/\1${US}\2/p" "${TMPD}/gt.defraw" > "${TMPD}/gt.def"
  sed -n "s/^\([a-z0-9-]*\)='\(.*\)'\$/\1${US}\2/p" "${TMPD}/gt.dump" > "${TMPD}/gt.usr"
  awk -F "${US}" -v all="${ALL}" -v US="${US}" -v dfile="${TMPD}/gt.def" '
    FILENAME == dfile { d[$1] = $2; if (!($1 in at)) { at[$1] = ++n; ord[n] = $1 } next }
    {
      if (all) { if (!($1 in at)) { at[$1] = ++n; ord[n] = $1 } d[$1] = $2 }
      else if (!($1 in d) || d[$1] != $2) { u[++m] = $1; uv[m] = $2 }
    }
    END {
      if (all) for (i = 1; i <= n; i++) print ord[i] US d[ord[i]]
      else for (i = 1; i <= m; i++) print u[i] US uv[i]
    }' "${TMPD}/gt.def" "${TMPD}/gt.usr" > "${TMPD}/gt.out"
  gtn=0
  while IFS="${US}" read -r gtname gtacc; do
    gtn=$((gtn + 1))
    if [ "${gtacc}" = disabled ]; then
      [ "${ALL}" -eq 1 ] || unmapped gnome-terminal "${gtschema} ${gtname} (unbound)" terminal
      continue
    fi
    gtkey=$(from_gtk "${gtacc}") || { unmapped gnome-terminal "${gtname} ${gtacc}" terminal; continue; }
    rec "${gtkey}" gnome-terminal "${gtname}" "$(yq_q "${gtname}")" terminal
  done < "${TMPD}/gt.out"
  [ "${gtn}" -gt 0 ] || [ "${ALL}" -eq 1 ] \
    || note "INFO gnome-terminal: no user-defined bindings found (use --all to include defaults)"
  return 0
}

# iterm2: key mappings from the com.googlecode.iterm2 preferences.  iTerm2 stores only what
# the user changed, so --all adds nothing here.  Mappings live in two places: the top-level
# GlobalKeyMap dict and, per profile, "New Bookmarks"[n]."Keyboard Map".  Both are dicts keyed
# `0x<unicode>-0x<modifier flags>-0x<keycode>` (see from_iterm2), valued {Action: int, Text: str}.
# A key present in several places is recorded once (first wins: global, then profiles in order).
#
# Reading the plist on macOS: `defaults export` writes it as XML, and `plutil -extract` pulls
# one key path out as JSON.  A whole-file `plutil -convert json` is avoided on purpose: the
# preferences hold Data and Date values, which JSON cannot represent, so it fails on real
# installs.  The pieces extracted here (the key maps) hold only numbers and strings.
# Test seam: CAPTURE_ITERM2_JSON names a JSON file shaped like
# {"GlobalKeyMap": {...}, "New Bookmarks": [{"Name": ..., "Keyboard Map": {...}}, ...]}.
# Status: only checked against a fixture; the note printed on success says so.

# iterm_json OUT PLIST: write the JSON for the key maps of PLIST to OUT; status 1 when the
# plist holds neither.
iterm_json() {
  itgk=$(plutil -extract GlobalKeyMap json -o - "$2" 2>/dev/null) || itgk=""
  [ -n "${itgk}" ] || itgk=null
  itcnt=$(plutil -extract "New Bookmarks" raw -o - "$2" 2>/dev/null) || itcnt=""
  case "${itcnt}" in ''|*[!0-9]*) itcnt=0 ;; esac
  [ "${itcnt}" -le 1000 ] || itcnt=1000
  if [ "${itgk}" = null ] && [ "${itcnt}" -eq 0 ]; then return 1; fi
  {
    printf '{"GlobalKeyMap": %s, "New Bookmarks": [' "${itgk}"
    itn=0; itsep=""
    while [ "${itn}" -lt "${itcnt}" ]; do
      itkm=$(plutil -extract "New Bookmarks.${itn}.Keyboard Map" json -o - "$2" 2>/dev/null) || itkm=""
      if [ -n "${itkm}" ]; then
        itnm=$(plutil -extract "New Bookmarks.${itn}.Name" raw -o - "$2" 2>/dev/null) || itnm=""
        itnj=$(ITNM="${itnm}" yq -n -o=json '"" + strenv(ITNM)' 2>/dev/null | tr -d '\n') || itnj=""
        [ -n "${itnj}" ] || itnj='""'
        printf '%s{"Name": %s, "Keyboard Map": %s}' "${itsep}" "${itnj}" "${itkm}"
        itsep=", "
      fi
      itn=$((itn + 1))
    done
    printf ']}\n'
  } > "$1"
  return 0
}

# iterm_action NUM TEXT PROFILE -> readable action text.  Only the numeric actions that are
# certain are named; any other keeps its number.
iterm_action() {
  case "$1" in
    10) ita="iTerm2 send escape sequence" ;;
    11) ita="iTerm2 send hex codes" ;;
    12) ita="iTerm2 send text" ;;
    13) ita="iTerm2 ignore" ;;
    *)  ita="iTerm2 action $1" ;;
  esac
  if [ "$1" != 13 ] && [ -n "$2" ]; then
    ittx=$(printf '%s' "$2" | cut -c1-40)
    [ "${ittx}" = "$2" ] || ittx="${ittx}..."
    ita="${ita}: ${ittx}"
  fi
  if [ -n "$3" ]; then
    itpn=$(printf '%s' "$3" | cut -c1-30)
    ita="${ita} (profile ${itpn})"
  fi
  printf '%s\n' "${ita}"
}

cap_iterm2() {
  itjson=${CAPTURE_ITERM2_JSON:-}
  if [ -z "${itjson}" ]; then
    { have defaults && have plutil; } || { absent iterm2 "not macOS (no defaults/plutil)"; return 0; }
    defaults export com.googlecode.iterm2 "${TMPD}/iterm.plist" >/dev/null 2>&1 && [ -s "${TMPD}/iterm.plist" ] \
      || { absent iterm2 "com.googlecode.iterm2 preferences not found"; return 0; }
    itjson="${TMPD}/iterm.json"
    iterm_json "${itjson}" "${TMPD}/iterm.plist" \
      || { absent iterm2 "no key mappings in the com.googlecode.iterm2 preferences"; return 0; }
  fi
  have yq || { absent iterm2 "yq not installed"; return 0; }
  [ -s "${itjson}" ] || { absent iterm2 "no iTerm2 preferences at ${itjson}"; return 0; }
  # Fields are tab separated and prefixed k:/p:/t: so none is empty (read would collapse it);
  # control characters are already replaced by yq, so a value cannot contain a tab or newline.
  cat > "${TMPD}/iterm.g.yq" <<'YQEOF'
select(tag == "!!map") | .["GlobalKeyMap"] | select(tag == "!!map") | to_entries | .[] | ["k:" + (.key | sub("[\x00-\x1f\x7f]"; "?")), ((.value | select(tag == "!!map") | .Action) // "?" | tostring | sub("[\x00-\x1f\x7f]"; "?")), "p:", "t:" + ((.value | select(tag == "!!map") | .Text | select(tag == "!!str") | sub("[\x00-\x1f\x7f]"; " ")) // "")] | join("\t")
YQEOF
  cat > "${TMPD}/iterm.p.yq" <<'YQEOF'
select(tag == "!!map") | .["New Bookmarks"] | select(tag == "!!seq") | .[] | select(tag == "!!map") | ((.Name | select(tag == "!!str") | sub("[\x00-\x1f\x7f]"; " ")) // "") as $n | .["Keyboard Map"] | select(tag == "!!map") | to_entries | .[] | ["k:" + (.key | sub("[\x00-\x1f\x7f]"; "?")), ((.value | select(tag == "!!map") | .Action) // "?" | tostring | sub("[\x00-\x1f\x7f]"; "?")), "p:" + $n, "t:" + ((.value | select(tag == "!!map") | .Text | select(tag == "!!str") | sub("[\x00-\x1f\x7f]"; " ")) // "")] | join("\t")
YQEOF
  yq -r '.' "${itjson}" >/dev/null 2>&1 || { absent iterm2 "preferences not parseable as JSON"; return 0; }
  { yq -r --from-file "${TMPD}/iterm.g.yq" "${itjson}" && yq -r --from-file "${TMPD}/iterm.p.yq" "${itjson}"; } \
    > "${TMPD}/iterm.rows" 2>/dev/null || { absent iterm2 "preferences not readable (unexpected structure)"; return 0; }
  ittab=$(printf '\t'); : > "${TMPD}/iterm.seen"; itcount=0
  while IFS="${ittab}" read -r itk ita itp itt; do
    [ -n "${itk}" ] || continue
    itk=${itk#k:}; itp=${itp#p:}; itt=${itt#t:}
    if itkey=$(from_iterm2 "${itk}" 2>/dev/null); then
      itid="key ${itkey}"
    else
      itkey=""; itid="raw ${itk}"
    fi
    grep -qxF -- "${itid}" "${TMPD}/iterm.seen" && continue
    printf '%s\n' "${itid}" >> "${TMPD}/iterm.seen"
    itcount=$((itcount + 1))
    if [ -z "${itkey}" ]; then unmapped iterm2 "${itk} (${ita})" terminal; continue; fi
    rec "${itkey}" iterm2 "$(iterm_action "${ita}" "${itt}" "${itp}")" native terminal
  done < "${TMPD}/iterm.rows"
  if [ "${itcount}" -eq 0 ]; then
    note "INFO iterm2: no user-defined key mappings found (iTerm2 stores only what was changed)"
  else
    note "INFO iterm2: parsed from preferences; verified against a fixture only, check the output on a Mac"
  fi
  return 0
}

# --------------------------------------------------------------------------------------

[ "${ALLAPPS}" -eq 0 ] || echo "capture: INFO os: not captured (no live binding list), nothing captured" >&2
for app in ${REQ}; do "cap_$(printf '%s' "${app}" | tr - _)"; done

echo "# Captured by scripts/keyboard/capture.sh.  Paste into keys.yaml, then run render.sh."
echo "# Review each 'action' (taken from the app) and add group/note as you like."
if [ -n "$(find "${TMPD}" -name "layer.*")" ]; then echo "layers:"; else echo "layers: []"; fi
emit_layer compositor 'Window manager / desktop'
emit_layer terminal   'Terminal emulator'
emit_layer tmux       'tmux'
emit_layer shell      'Shell line editing'
emit_layer vim        'vim'
