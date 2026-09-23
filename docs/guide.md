<!-- Hand-written. Cheatsheets are generated separately: see the links below. -->

# Dotfiles guide

Everything below is hand-written reference for how the keyboard standard, vim's shipped
defaults and the vim Go IDE fit together. Bindings and colours themselves are generated
elsewhere and kept in their own cheatsheets, not duplicated here:

- [Keyboard cheatsheet](keyboard-cheatsheet.md) - every binding, all layers, generated from
  `keys.yaml`.
- [Colour cheatsheet](colors-cheatsheet.md) - every colour, all layers, generated from
  `colors.yaml`.

## Table of contents

- [Keyboard standard](#keyboard-standard)
  - [Change a binding](#change-a-binding)
  - [Set up a machine](#set-up-a-machine)
  - [Terminals](#terminals)
  - [Modifiers](#modifiers)
  - [Capture order](#capture-order)
  - [tmux over ssh](#tmux-over-ssh)
  - [Navigation keys](#navigation-keys)
  - [Pitfalls / notes](#pitfalls--notes)
- [vim defaults](#vim-defaults)
  - [Buffers](#buffers)
  - [Windows and splits](#windows-and-splits)
  - [Panes (tmux, hosting vim)](#panes-tmux-hosting-vim)
  - [Cursor movement: Normal mode](#cursor-movement-normal-mode)
  - [Editing: Normal mode](#editing-normal-mode)
  - [Editing: Insert mode](#editing-insert-mode)
  - [Command-line mode](#command-line-mode--------)
- [vim IDE (Go)](#vim-ide-go)
  - [Try it in 60 seconds](#try-it-in-60-seconds)
  - [What it's built from](#whats-its-built-from)
  - [Completion](#completion-prediction)
  - [Navigation](#navigation-1)
  - [Errors and warnings](#errors-and-warnings)
  - [Status bar](#status-bar)
  - [Formatting](#formatting)
  - [Debugging](#debugging)
  - [Where it lives in the repo](#where-it-lives-in-the-repo)
  - [When something doesn't work](#when-something-doesnt-work)

# Keyboard standard

One physical finger position means one thing on every machine, in every layer: compositor,
terminal, tmux, shell and vim.

`keys.yaml`, at the repo root, is the single source for every layer's bindings.

## Change a binding

```sh
$EDITOR keys.yaml                       # add, change or remove a binding
scripts/keyboard/render.sh              # regenerate every fragment that changed
scripts/keyboard/render.sh --check      # exit 1 if a committed fragment is stale
git add -A && git commit                # the yaml and its fragments, together
```

Then reload whatever you changed:

| Layer | Fragment (GENERATED, committed) | Loaded by | Reload |
| --- | --- | --- | --- |
| compositor | `.config/labwc/rc.xml`, between the markers | labwc | `labwc --reconfigure` |
| compositor, terminal | `linux/gnome-keys.sh` | `linux/terminal.sh` | `scripts/keyboard/linux/terminal.sh` |
| terminal | `.config/kitty/keys.conf` | `include` in `kitty.conf` | new kitty window |
| tmux | `.tmux/keys.conf` | `source-file` in `.tmux.conf` | `tmux kill-server` |
| shell | `.shell/.common.d/keys.sh` | the `.common.d` loader | new shell |
| vim | `.vim/keys.vim` | `runtime keys.vim` in `.vimrc` | restart vim |

Never edit a file whose first line says GENERATED: the next render overwrites it. The
renderer needs mikefarah's Go `yq` v4. Nothing else does, because the fragments are
committed. Bare script paths in this section (`render.sh`, `linux/…`, `macos/…`) are
relative to `scripts/keyboard/`.

## Set up a machine

```sh
scripts/keyboard/linux/apply.sh    # xkb modifier remap, then terminal.sh (GNOME, X11)
scripts/keyboard/macos/apply.sh    # Caps -> Control via hidutil, kept by a LaunchAgent
```

`install.sh` runs the right one through `scripts/install.d/30-keyboard.sh`. Both are
idempotent and no-op on the wrong platform. Neither installs packages or writes into
`$HOME`.

Two settings no script can make:

- **iTerm2:** Profiles > Keys > Left and Right Option key > `Esc+`. Without it no Alt
  binding reaches tmux or vim.
- **Touch Bar MacBook:** Settings > Keyboard > Touch Bar shows F1 to F12.

## Terminals

| Tier | Terminal | Option/Alt sends ESC |
| --- | --- | --- |
| 1 | kitty | Linux by default; `macos_option_as_alt both` in `kitty.conf` on macOS |
| 1 | gnome-terminal | by default |
| 1 | iTerm2 | the `Esc+` setting above |
| 2 | WSL (Windows Terminal) | by default |

A behaviour that cannot work on all three tier-1 terminals does not ship.

## Modifiers

Three modifier positions exist on every target keyboard, and every binding uses only those.

| Finger position | Modifier | Owned by | Never used for |
| --- | --- | --- | --- |
| Caps Lock | ctrl | signals, the tmux prefix `C-x`, vim `<C-…>` | copy or paste in a terminal |
| left of space | super (Cmd on macOS) | compositor, terminal emulator | anything in tmux or vim |
| two left of space | alt (Option on macOS) | tmux, vim splits | terminal-emulator shortcuts |

- **super** has no byte encoding, so only the compositor and the emulator can see it.
- **alt** arrives as an ESC prefix, so tmux and vim can bind it. Frequent tmux actions are
  unprefixed Alt keys, and `C-x` is kept for rare ones.
- **Linux GUI apps** (Firefox, Nautilus) keep `Ctrl-C` and `Ctrl-V`, reached from Caps. They
  share the same clipboard.

## Capture order

A keystroke passes `os -> compositor -> terminal -> tmux -> shell | vim`, and the first
layer that binds it wins. The rule for placing a binding: bind it in the **outermost layer
that can still see it**. Too far out, and the inner layers never receive it. Too far in, and
an outer layer eats it first.

| Binding group | Layer | Why there |
| --- | --- | --- |
| Caps -> Control, Alt/Super swap | os (`linux/apply.sh`, `macos/apply.sh`) | Only the OS can rewrite a keysym, and every layer above inherits the result. |
| Per-machine remaps | os (`linux/machines/<host>.sh`) | Selected by hostname, so the standard stays one file and the exception stays visible. |
| `Super-Tab`, window management | compositor (labwc, GNOME) | The compositor sees keys before any window does. |
| `Super-C/V`, tabs, windows | terminal | The innermost layer that can see super. |
| `Alt-…` panes, windows, scrollback | tmux, root table | Alt reaches tmux; the root table means no prefix chord. |
| `Alt-h/j/k/l`, `Alt-Shift-h/j/k/l` | tmux, forwarded to vim | tmux forwards them when the pane runs vim (`pass: vim`), so one key crosses pane and split boundaries. |
| Edge handoff back to tmux | vim (`vimide#focus`, `vimide#resize`) | Only vim knows whether a split exists in that direction. |
| `Alt-Tab` | tmux, never forwarded | The way out of any pane, even one running a program that swallows Alt. |
| `PageUp` | tmux, forwarded to pagers | Scrollback in a shell pane; paging in less, man, vim. |
| Home, End, Ctrl-arrows, Delete | shell, and tmux copy-mode | Each layer decodes its own input, so each needs its own table. |
| yank to clipboard | vim (`.vimrc` hook, `vimide#clip`) | Convenience only, local only. `Super-C` is the path that always works. |

## tmux over ssh

Every shell should live in a tmux session local to the host it's actually running on.
`.shell/.common.d/tmux.sh`'s autostart function runs identically whether the shell is local
or arrived over ssh (dotfiles are assumed installed everywhere): an ssh session gets its own
"main" one level in, nested inside whatever local session the pane already belongs to.

That makes almost every tmux binding ambiguous, because nearly all of them (`Alt-…` panes,
windows, focus, resize, and the `Ctrl-x` prefix itself) live on the root key table, which is
always live on the **outer** (local) session — a nested remote session never sees them
otherwise. `Alt-x` is the passthrough toggle: it flips the outer session's `key-table` to
`off`, an otherwise-unbound table, so every raw byte — `Ctrl-x` included — passes straight
through to the pane and reaches the nested session's own identical bindings instead. The
status line changes background (`@status-passthrough-bg`, `colors.yaml`) while it's active,
so it's always visible which session is currently listening. Pressing `Alt-x` again (now
reaching the outer session, since passthrough is off) flips it back.

**Self-loop guard.** Sshing back into the same host — directly, or through a different
intermediate host (`laptop -> server01 -> laptop`) — would otherwise nest a session inside
itself. `tmux.sh` guards this in two layers: a direct self-connection is caught via
`$SSH_CONNECTION` (loopback-routed, so client and server IPs coincide); a longer chain is
tracked in `LC_DOTFILES_TMUX_CHAIN`, forwarded across hops by piggybacking on the
near-universal `SendEnv`/`AcceptEnv LC_*` default (no wrapper, no sshd_config edit needed).
See the comments in `tmux.sh` for the full reasoning and the known gap (chain tracking is
best-effort, depending on that default being present on a given hop).

## Navigation keys

These mean the same thing in every layer.

| Key | Meaning | shell | tmux copy-mode | vim |
| --- | --- | --- | --- | --- |
| Home | start of line | `beginning-of-line` | `start-of-line` | `0` |
| End | end of line | `end-of-line` | `end-of-line` | `$` |
| Ctrl-Left | previous word start | `backward-word` / `vi-bword` | `previous-word` | `b` |
| Ctrl-Right | next word start | `forward-word` / `vi-fword` | `next-word` | `w` |
| Delete | delete char forward | `delete-char` | read-only | `x` |
| Ctrl-Delete | delete word forward | `kill-word` | read-only | `dw` |
| PageUp | page up | enters tmux scrollback | `page-up` | page up |
| PageDown | page down | not bound | `page-down` | page down |
| Ctrl-Home | top of buffer | not bound | `history-top` | `gg` |
| Ctrl-End | bottom of buffer | not bound | `history-bottom` | `G` |

## Pitfalls / notes

### Terminal input

- **One key, four byte forms.** Home can arrive as `ESC [ H` (CSI: kitty, VTE normal mode),
  `ESC O H` (SS3: VTE application mode), `ESC [ 1 ~` (what tmux re-emits) or `ESC [ 7 ~`
  (rxvt). End and Ctrl-Left/Right have their own four forms. The shell layer binds every
  form (`sequences:` in `keys.yaml`), because zsh on its own binds only the one form terminfo
  names for `$TERM`. Home silently did nothing in kitty until all four were bound.
- **Never bind the rxvt Ctrl-Right (`ESC [ 5 C`) in vim.** vim reads the tail as `5C`
  (change five lines) and destroys the buffer. It is bound in the shells only.
- **vim needs Alt+letter declared, and must not declare Alt+arrow.** Alt+letter arrives as a
  bare ESC prefix, which vim does not decode, so `keys.vim` runs `set <M-h>=\<Esc>h` for each.
  Alt+arrow arrives as `ESC [ 1 ; 3 <letter>`, which vim decodes itself, and `set <M-Up>=`
  fails with E518.
- **Alt depends on short escape timeouts.** tmux runs with `escape-time 0` and vim with
  `ttimeoutlen=25`, so neither waits long to tell a bare Escape from an Alt key. Raising
  either makes Escape and Alt feel laggy.
- **`Alt-[` and `Alt-]` are best effort.** Traditionally they send `ESC [` and `ESC ]`, the
  starts of real escape sequences. tmux binds them (swap pane) and relies on
  `extended-keys csi-u` to tell them apart. Never put anything essential there.
- **bash word motion uses `vi-fword` / `vi-bword`.** readline's `forward-word` stops at the
  end of a word, while zsh, tmux and vim stop at the start of the next one. zsh pins
  `WORDCHARS=''` so a word ends where bash's does.
- **The bash prompt wraps every colour escape in `\[ \]`.** Unwrapped, readline counts them
  as printable columns and draws the cursor in the wrong place after Home, End or
  Ctrl-arrows.

### Layer conflicts

- **gnome-terminal ships `switch-to-tab-N` on Alt-N**, which would take tmux's window keys.
  `gnome-keys.sh` moves the tabs to Super-N.
- **GNOME Shell grabs Super-1..9, Super-A, Super-N and sometimes Super-V.** A compositor grab
  makes a terminal binding look set and do nothing, with no error. `terminal.sh` releases
  them, outermost layer first. The Super-V release is unconditional, because a grab there
  kills paste everywhere.
- **GNOME binds the app switcher to both Super-Tab and Alt-Tab.** The Alt copy shadows
  tmux's pane cycling, so it is pinned to Super-Tab alone.
- **labwc takes Super-A (maximize) and Super-T (launch kitty).** gnome-terminal's select-all
  and new-tab never fire under labwc. kitty binds neither key, so labwc with kitty is
  unaffected. The cheatsheet lists every shadowed key.
- **`apply.sh` does nothing on labwc.** It knows only GNOME gsettings and X11 setxkbmap;
  labwc reads xkb options from `.config/labwc/environment`, which currently sets only
  `caps:ctrl_modifier`, so the Alt/Super swap is missing there.
- **Ctrl-Left/Right are not bound in tmux's root table**, so they reach the shell or vim.
  They are bound in copy-mode only.
- **bash's own Alt-Left/Right word motion is left in place.** tmux takes those keys first,
  so it only matters outside tmux, where nothing conflicts.

### tmux and vim

- **Forwarding into vim is one-way.** Once tmux sends Alt-h to vim, a vim already in its
  leftmost split would swallow the key and trap focus. `vimide#focus` compares `winnr()`
  before and after, and calls `tmux select-pane` if nothing moved. That is a tmux command,
  not a keystroke, so it cannot loop.
- **Resize decides first, then acts.** Resizing and checking for a change fails with a single
  window: `<C-w>-` really shrinks it, so the handoff never fires. `vimide#resize` asks
  `winnr('h'/'j'/'k'/'l')` whether a neighbour exists, and hands off to
  `tmux resize-pane` when none does.
- **`is_vim` is backslash-free on purpose.** The string passes through tmux, sh and grep, and
  a `\S` would reach grep as a literal backslash.
- **PageUp tests `alternate_on` or a command-name match.** `LESS=-EXFR`
  (`.shell/.common.d/home.sh`) keeps less off the alternate screen, so `alternate_on` alone
  would send PageUp into tmux scrollback instead of less.
- **Copy-mode keys are bound in both `copy-mode` and `copy-mode-vi`.** `mode-keys` follows
  `$EDITOR`, so a box without vim lands in `copy-mode`.
- **Selection colours are numbers, not names.** tmux's `blue` is colour4 and vim's `Blue` is
  colour12, so matching names produce different colours.
- **`Alt-x` shadows readline's default `M-x`** (execute-named-command) in every shell pane,
  same as any other `Alt-<letter>` binding here: tmux's root table intercepts it before the
  shell ever sees it.

### Copy and paste

- **The terminal owns the clipboard, not tmux or vim.** The earlier design had tmux and vim
  write OSC 52. It worked in kitty and iTerm2 and was silently dead in gnome-terminal:
  VTE has never implemented OSC 52. A terminal-side selection also works over ssh with
  nothing installed on the far end.
- **tmux mouse is on, so a plain drag makes a tmux selection.** `Super-C` then has nothing
  to copy. Hold Shift (Option in iTerm2) while dragging for a terminal selection, or press
  `Alt-m` to turn tmux mouse reporting off.
- **Ctrl-Shift-C is rejected** as the copy key. It is a chord, and it sits at a different
  finger position from macOS's Cmd-C.
- **vim's yank-to-clipboard is local only.** Debian's terminal vim is built `-clipboard`, so
  it pipes to `pbcopy`, `wl-copy`, `xclip` or `xsel`. Over ssh, yanks stay in vim.

### Keyboards and renderer

- **The bottom-left corner is not a modifier anchor.** It is Ctrl on the XPS and Pixelbook,
  and fn on the MacBooks. That is why Caps carries Control.
- **Nothing essential goes on F11 or F12.** The Pixelbook's top row stops at F10.
- **The Pixelbook has no physical Super key.** `linux/machines/pixelbook.sh` rewrites the
  layout with xkbcomp instead of the stock swap.
- **Debian's `yq` package is the wrong yq.** It is a Python jq wrapper. Install `yq-go`;
  `render.sh` checks the version and refuses anything else.
- **XML comments cannot contain `--`.** The labwc section headers use `=`; a `--` in a note
  would make `rc.xml` invalid. Check with `xmllint --noout .config/labwc/rc.xml`.
- **xterm, alacritty and Terminal.app are no longer supported.** `.Xresources` and
  `alacritty.toml` are still linked but not maintained, and no binding is rendered for them.

# vim defaults

vim's own keys, as shipped: no mapping in this repo changes them unless a row says so.
Bindings this repo *does* add, in vim and every other layer, are in
[keyboard-cheatsheet.md](keyboard-cheatsheet.md).

Notation: `Ctrl-x`, `Alt-x` (Option on macOS), `Shift-x`.

## Buffers

No mapping in this repo changes these.

| Command | Does |
| ------- | ---- |
| `:e {file}` | edit/open a file in the current window |
| `:bn` / `:bp` | next / previous buffer |
| `:b {N\|name}` | jump to buffer by number or name |
| `:ls` / `:buffers` | list open buffers |
| `:bd` | delete (close) current buffer |
| `:bd {N}` | delete buffer N |
| `Ctrl-^` | toggle to the alternate (previously edited) buffer |
| `:w` | write current buffer |
| `:wa` | write all changed buffers |
| `:q` / `:q!` | close window / discard changes and close |
| `:x` / `ZZ` | write if changed, then close |
| `:qa` / `:qa!` | close all windows / discard all and quit |

## Windows and splits

vim defaults, all under the `Ctrl-w` prefix. `Alt-h/j/k/l` and `Alt-Shift-h/j/k/l` are this
repo's fast path for focus and resize (see [keyboard-cheatsheet.md](keyboard-cheatsheet.md));
everything here is default vim.

| Command | Does |
| ------- | ---- |
| `:sp` / `Ctrl-w s` | horizontal split |
| `:vs` / `Ctrl-w v` | vertical split |
| `Ctrl-w w` | cycle to next window |
| `Ctrl-w h/j/k/l` | move focus left/down/up/right |
| `Ctrl-w H/J/K/L` | move the window itself to the far left/bottom/top/right |
| `Ctrl-w =` | equalize all window sizes |
| `Ctrl-w +/-` | grow/shrink height |
| `Ctrl-w </>` | shrink/grow width |
| `Ctrl-w \_` / `Ctrl-w \|` | maximize height / width |
| `Ctrl-w o` | close all windows but this one |
| `Ctrl-w q` / `:close` | close this window |
| `Ctrl-w T` | move window into its own tab |
| `:tabnew`, `gt`, `gT` | new tab, next tab, previous tab |

## Panes (tmux, hosting vim)

tmux panes are not vim, but vim splits live inside them and share the Alt keys. The full
set, including which keys tmux forwards into vim, is in
[keyboard-cheatsheet.md](keyboard-cheatsheet.md).

## Cursor movement: Normal mode

| Key | Does |
| --- | ---- |
| `h j k l` | left / down / up / right |
| `w` / `b` / `e` | next word start / previous word start / word end |
| `0` / `^` / `$` | start of line / first non-blank / end of line |
| `gg` / `G` | first line / last line |
| `{N}G` or `:{N}` | go to line N |
| `{` / `}` | previous / next paragraph |
| `%` | jump to matching bracket |
| `Ctrl-u` / `Ctrl-d` | half-page up / down (`Ctrl-Up` / `Ctrl-Down` do the same here) |
| `Ctrl-f` / `Ctrl-b` | full page down / up |
| `H` / `M` / `L` | top / middle / bottom of window |
| `*` / `#` | next / previous occurrence of word under cursor |
| `f{c}` / `F{c}` | jump to next/previous occurrence of char `c` on the line |
| `t{c}` / `T{c}` | jump to just before next/previous occurrence of char `c` |
| `m{a}` | set mark `a` |
| two backticks + `{a}`, or `'{a}` | jump to mark `a` (exact position / start of line) |

## Editing: Normal mode

| Key | Does |
| --- | ---- |
| `i` / `a` | insert before / after cursor |
| `I` / `A` | insert at start / end of line |
| `o` / `O` | open new line below / above, enter insert mode |
| `x` / `X` | delete char forward / backward |
| `dd` | delete (cut) line |
| `dw`, `de`, `d$`, `d0` | delete to next word / word end / end of line / start of line |
| `cc` / `cw` | change line / change word (delete + insert) |
| `yy` | yank (copy) line; this repo also copies every yank to the system clipboard |
| `p` / `P` | paste after / before cursor |
| `u` / `Ctrl-r` | undo / redo |
| `.` | repeat last change |
| `r{c}` | replace char under cursor with `c` |
| `~` | toggle case of char under cursor |
| `>>` / `<<` | indent / outdent line |
| `{N}{cmd}` | prefix any of the above with a count, e.g. `3dd` deletes 3 lines |
| `v` / `V` / `Ctrl-v` | start visual / visual-line / visual-block selection |
| `:s/pat/rep/` | substitute on current line; add `g` for all matches, `%` before `s` for whole file |

## Editing: Insert mode

| Key | Does |
| --- | ---- |
| `Esc` | back to Normal mode |
| arrow keys | move cursor (breaks the insert "undo chunk") |
| `Ctrl-w` | delete word before cursor |
| `Ctrl-u` | delete to start of line |
| `Ctrl-t` / `Ctrl-d` | indent / outdent current line |
| `Ctrl-o` | run one Normal-mode command, then return to Insert |
| `Ctrl-r {reg}` | insert contents of register `reg` (e.g. `Ctrl-r "` for last yank/delete) |
| `Ctrl-n` / `Ctrl-p` | next / previous keyword completion match |
| `Ctrl-v {code}` | insert a literal character by code |
| paste (`Cmd-V`/`Super-V`) | bracketed paste, so no auto-indent staircase and no mapping needed |

## Command-line mode (`:`, `/`, `?`)

| Key | Does |
| --- | ---- |
| `:` | enter command-line mode |
| `/pattern`, `?pattern` | search forward / backward |
| `n` / `N` | repeat last search, same / opposite direction |
| `Ctrl-a` / `Ctrl-e` | start / end of the command line (vim default; this repo's `Ctrl-a` / `Ctrl-e` maps cover Normal, Insert and Visual only) |
| `Tab` | complete command/filename |
| Up / Down or `Ctrl-p` / `Ctrl-n` | previous / next command-line history entry |

# vim IDE (Go)

Open a `.go` file inside a Go module and it works: completion pops up as you type, F12 jumps
to a definition, errors are underlined, and F5 starts the debugger. This section covers the
keys and what you see on screen. Every key is defined in `keys.yaml` and listed in
[keyboard-cheatsheet.md](keyboard-cheatsheet.md); vim's own keys are in
[vim defaults](#vim-defaults) above.

Go is the only language wired up so far. Other languages use the same pieces and are on the
backlog (see the repo's `CLAUDE.md`, "Future sprint").

## Try it in 60 seconds

1. `vim main.go` (any file in a directory with a `go.mod`)
2. Type `fmt.Pri` in insert mode: a popup lists `Print`, `Printf`, `Println`
3. `Ctrl-n` to pick one, `Ctrl-y` to accept it
4. `Esc`, put the cursor on a function name, press `F12`: you land on its definition
5. `Ctrl-o` jumps back
6. Put the cursor on a line in `main()`, press `F9` (breakpoint), then `F5` and pick
   "Launch package": the program stops on that line

## What it's built from

| Piece | Does | Upstream docs |
| ----- | ---- | ------------- |
| vim's `syntax/go.vim` | highlighting | [vim-go `g:go_highlight_*` options][vim-go-doc] (the file is maintained there) |
| [yegappan/lsp][lsp] | LSP client: completion, go to, diagnostics, formatting | [`doc/lsp.txt`][lsp-doc], [server configs][lsp-configs] |
| [gopls][gopls] | the Go language server | [gopls features][gopls-features], [settings][gopls-settings] |
| [vimspector][vimspector] | debugger UI (DAP client) | [README][vimspector], [`doc/vimspector.txt`][vimspector-doc], [configuration reference][vimspector-config] |
| [delve][delve] | the Go debugger, run as `dlv dap` | [delve docs][delve-docs], [DAP server][delve-dap] |

The two plugins are git submodules in `.vim/bundle/` and load through pathogen. The
upstream doc links point at the commits pinned here, so they describe the installed
version.

**Requirements.** yegappan/lsp needs vim 9.0+. vimspector needs vim built with `+python3`
(on Debian that means `vim-nox`, not `vim`; check with `vim --version | grep python3`).
`gopls` and `dlv` must be on `PATH`:

```sh
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
```

If any of these is missing, vim still starts without errors: the keys fall back to plain
vim or print one line saying what's missing.

## Completion (prediction)

Suggestions appear automatically as you type, including right after a `.`. Nothing is
selected or inserted until you choose.

| Key (insert mode) | Does |
| ----------------- | ---- |
| `Ctrl-n` / `Ctrl-p` | select next / previous suggestion (inserts it as a preview) |
| `Down` / `Up` | select next / previous without inserting it |
| `Ctrl-y` | **accept** the selected suggestion (works after either way of selecting) |
| `Enter` | after `Down`/`Up`: accept, no new line. After `Ctrl-n`/`Ctrl-p`: accept **and** start a new line. Nothing selected: close the popup |
| `Ctrl-e` | close the popup and put back what you typed |
| `Esc` | close the popup and leave insert mode |
| `Tab` | not a completion key: inserts a tab |

- The popup narrows as you type. Matching is fuzzy, so `prf` finds `Printf`.
- The selected suggestion's documentation shows in a second popup beside the menu.
- Inside a call's parentheses, a popup shows the function signature (for example
  `Printf(format string, a ...any)`). It updates as you type arguments.
- With no language server (another filetype, or gopls missing), `Ctrl-n` / `Ctrl-p` still
  complete words from open buffers. That's vim's own keyword completion.

Upstream: [`:help lsp-ins-mode-completion`][lsp-doc] and the `autoComplete`,
`completionMatcher` and `showSignature` options in the same file.

## Navigation

| Key | Does | Without a server |
| --- | ---- | ---------------- |
| `F12` | go to definition | tag jump (`Ctrl-]`), if there is a tags file |
| `Ctrl-Shift-F12` | go to declaration | vim's `gD` |
| `Ctrl-F12` | go to implementation (interface to concrete type) | one-line message |
| `Shift-F12` | list references (location list; `Enter` jumps) | one-line message |
| `Alt-F12` | hover: type and docs in a popup | vim's `K` |
| `F2` | rename the symbol everywhere (asks for the new name) | one-line message |
| `Ctrl-]` | go to definition (gopls answers vim's tag lookup) | tag jump |
| `Ctrl-o` / `Ctrl-i` | jump back / forward | same |

More commands without keys: `:LspGotoTypeDef`, `:LspPeekDefinition` (opens in a popup),
`:LspDocumentSymbol`, `:LspSymbolSearch {name}`, `:LspOutline`, `:LspIncomingCalls`,
`:LspCodeAction`, `:LspOrganizeImports`. The full list is in [`doc/lsp.txt`][lsp-doc].

## Errors and warnings

gopls checks the file as you type and again on save. syntastic is turned off for Go so the
same errors don't show up twice.

**In the text.** The code with the problem is highlighted with vim's spell-check colours:

| Severity | Highlight group | Linked to (default look) |
| -------- | --------------- | ------------------------ |
| error | `LspDiagInlineError` | `SpellBad` (usually red) |
| warning | `LspDiagInlineWarning` | `SpellCap` (usually blue) |
| info | `LspDiagInlineInfo` | `SpellRare` |
| hint | `LspDiagInlineHint` | `SpellLocal` |

**In the sign column** (left of the line numbers): `E>` error, `W>` warning, `I>` info,
`H>` hint. The column appears only while the buffer has a sign in it.

**Reading the message.** Nothing is shown automatically (virtual text is off because it
crowds narrow panes). Use:

| Command | Does |
| ------- | ---- |
| `:LspDiag current` | show the message for the cursor line in a popup |
| `:LspDiag next` / `:LspDiag prev` | jump to the next / previous problem |
| `:LspDiagNextWrap` / `:LspDiagPrevWrap` | same, wrapping at the ends of the file |
| `:LspDiag first` / `:LspDiag last` | jump to the first / last problem |
| `:LspDiag show` | list every problem in the location list (`Enter` jumps, `:lclose` closes) |
| `:LspDiag highlight toggle` | turn the highlighting and signs off / on |

There are no keys for next / previous yet: `vimide#lsp('diag_next')` and `('diag_prev')`
exist and are listed, commented out, in `keys.yaml` (group `code`). Pick a key, uncomment,
run `scripts/keyboard/render.sh`.

To change the colours, link the groups above in `.vimrc`, for example
`highlight link LspDiagInlineError ErrorMsg`. Upstream: [`:help lsp-diagnostics`][lsp-doc]
and [`:help lsp-highlight-groups`][lsp-doc].

## Status bar

The status line at the bottom of each window reads, left to right:

```
[unix][go] /home/me/prj/t/main.go [E:1 W:0][+]        12/40  7 0x0066
 │     │    │                      │       │            │  │  │  │
 │     │    │                      │       │            │  │  │  └ character under the cursor, hex
 │     │    │                      │       │            │  │  └ column
 │     │    │                      │       │            │  └ total lines
 │     │    │                      │       │            └ current line
 │     │    │                      │       └ [+] = unsaved changes
 │     │    │                      └ LSP errors / warnings in this buffer
 │     │    └ full path
 │     └ filetype
 └ line endings
```

- `[E:n W:n]` only appears when the buffer has a server attached and at least one error or
  warning. No count means clean (or no server; check with `:LspShowAllServers`).
- For another filetype, syntastic's flag can appear in the same spot.

## Formatting

Saving a Go file formats it through gopls (same result as `gofmt`). Indentation is tabs
shown 4 wide, following gofmt; other filetypes keep the global 2-space indent. Imports are
not fixed on save. Run `:LspOrganizeImports` to add and remove them. `:LspFormat` formats
without saving.

## Debugging

| Key (normal mode) | Does |
| ----------------- | ---- |
| `F5` | start (asks which configuration) / continue to the next breakpoint |
| `Shift-F5` | stop the program and close the debugger windows |
| `Ctrl-F5` | restart with the same configuration |
| `F9` | toggle a breakpoint on the cursor line |
| `F10` | step over |
| `F11` | step into |
| `Shift-F11` | step out |
| `F8` | show the value of the expression under the cursor in a popup |

`F5` asks which configuration to run. All three work for every Go file with no project setup:

| Configuration | Runs |
| ------------- | ---- |
| Launch package | the package in the current file's directory (`dlv debug`) |
| Launch test | that package's tests (`dlv test`) |
| Attach to process | a running process; asks for the PID |

**Screen layout while debugging:**

| Window | Shows | Keys in it |
| ------ | ----- | ---------- |
| Variables (top left) | locals, `+` to expand | `Enter` expand / collapse, `Ctrl-Enter` set the value |
| Watches | expressions you add | `i`, type an expression, `Enter` |
| Stack trace | threads and frames | `Enter` jumps to that frame |
| code (right) | source; `▶` marks the current line (highlighted), `●` marks each breakpoint | the keys above |
| terminal | the program's own output | |
| Console (bottom) | delve messages and evaluation results | `i`, type an expression, `Enter` |

Commands: `:VimspectorEval {expr}`, `:VimspectorWatch {expr}`, `:VimspectorBreakpoints`
(list them all), `:VimspectorShowOutput Console`. Upstream: [`doc/vimspector.txt`][vimspector-doc]
and the [vimspector README][vimspector].

**Your own configurations.** The defaults live in
`.vim/vimspector-config/configurations/linux/go/go.json` (macOS reads the same file through
a symlink). For program arguments or environment variables, add a `.vimspector.json` to the
project root. The format is in the [configuration reference][vimspector-config], and the
delve-specific keys are in the [delve DAP docs][delve-dap]. The `delve` adapter runs the
`dlv` on `PATH`, so `:VimspectorInstall` is never needed.

## Where it lives in the repo

| File | Holds |
| ---- | ----- |
| `.vimrc` | plugin loading guards, Go highlight options, LSP start hook, statusline |
| `.vim/autoload/vimide.vim` | `vimide#lsp_setup` (server list: `s:servers`), `vimide#lsp`, `vimide#debug`, `vimide#lsp_status` |
| `.vim/after/ftplugin/go.vim` | Go indentation |
| `.vim/vimspector-config/` | delve adapter and Go launch configurations |
| `keys.yaml` | the F-keys (groups `code` and `debug`) |

## When something doesn't work

| Symptom | Check |
| ------- | ----- |
| No popup, no `[E:..]`, F12 says "no language server" | `:LspShowAllServers`, then `which gopls` in the shell vim started from |
| Server running but wrong answers | `:LspServer restart`; logs via `:LspServer debug on`, then `:LspServer debug messages` |
| F5 says "debugger not available" | `vim --version \| grep python3` must show `+python3` |
| Debugger starts then stops | `which dlv`; `:VimspectorToggleLog` for the log |
| F11 makes the terminal full screen | gnome-terminal: run `scripts/install.d/30-keyboard.sh` |
| `:help lsp` or `:help vimspector` says no help | run `:Helptags` once (pathogen builds the plugins' help index) |

[lsp]: https://github.com/yegappan/lsp
[lsp-doc]: https://github.com/yegappan/lsp/blob/58eac06e81bad174cfa897614ae01adf0d31d10a/doc/lsp.txt
[lsp-configs]: https://github.com/yegappan/lsp/blob/58eac06e81bad174cfa897614ae01adf0d31d10a/doc/configs.md
[vimspector]: https://github.com/puremourning/vimspector/blob/34099d18d8957bb3db5f396c8ca993ffb246a437/README.md
[vimspector-doc]: https://github.com/puremourning/vimspector/blob/34099d18d8957bb3db5f396c8ca993ffb246a437/doc/vimspector.txt
[vimspector-config]: https://puremourning.github.io/vimspector/configuration.html
[gopls]: https://go.dev/gopls/
[gopls-features]: https://go.dev/gopls/features/
[gopls-settings]: https://go.dev/gopls/settings
[delve]: https://github.com/go-delve/delve
[delve-docs]: https://github.com/go-delve/delve/tree/master/Documentation
[delve-dap]: https://github.com/go-delve/delve/blob/master/Documentation/api/dap/README.md
[vim-go-doc]: https://github.com/fatih/vim-go/blob/master/doc/vim-go.txt
