# Keyboard standard

One physical finger position means one thing on every machine, in every layer: compositor,
terminal, tmux, shell and vim.

- **Bindings:** `keys.yaml`, the single source for every layer.
- **Cheatsheet:** `keyboard-cheatsheet.md`, generated. It has the capture-chain table and the
  list of shadowed keys.
- **vim's own keys:** `vim-defaults.md`.

`keys.yaml` sits at the repo root. Bare script paths below (`render.sh`, `linux/…`,
`macos/…`) are relative to `scripts/keyboard/`.

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
committed.

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
