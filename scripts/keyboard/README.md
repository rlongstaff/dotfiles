# Keyboard standard

One physical finger position means one thing on every machine and every keyboard.

`keys.yaml` is the binding list, for every layer from the compositor to vim, in the order
those layers capture a keystroke. `CHEATSHEET.md` is generated from it. This file is the
reasoning behind it.

## Editing a binding

```sh
$EDITOR scripts/keyboard/keys.yaml     # change, add or remove a binding
scripts/keyboard/render.sh              # regenerate every fragment that changed
scripts/keyboard/render.sh --check      # exit 1 if a committed fragment is stale
```

Commit the yaml and the regenerated files together. Never edit a file whose first line
says GENERATED; the next render overwrites it.

| Layer | Rendered to | Loaded by |
| --- | --- | --- |
| compositor | `.config/labwc/rc.xml` (between markers), `linux/gnome-keys.sh` | labwc; `linux/terminal.sh` |
| terminal | `.config/kitty/keys.conf`, `linux/gnome-keys.sh` | `kitty.conf` include; `linux/terminal.sh` |
| tmux | `.tmux/keys.conf` | `.tmux.conf` `source-file` |
| shell | `.shell/.common.d/keys.sh` | the `.common.d` loader, bash and zsh |
| vim | `.vim/keys.vim` | `.vimrc` `runtime keys.vim` |

The renderer needs mikefarah's Go `yq` v4 (`yq-go` on Debian, `yq` in Homebrew). Nothing
else does: the fragments are committed, so a machine without yq still has every binding.

## Supported terminals

 - **Tier 1:** kitty, gnome-terminal, iTerm2. A behaviour that cannot be made to work on
   all three does not ship.
 - **Tier 2:** WSL (Windows Terminal). Expected to work; not a reason to hold a change.
 - **Unsupported:** xterm, alacritty, Terminal.app. `.Xresources` and `alacritty.toml` are
   still linked but no longer maintained.

## The three modifier anchors

Six target keyboards, and only three *modifier* positions are in the same place on all of
them. Those three carry the meaning; every binding in this standard is expressed in terms
of them, and nothing depends on a modifier that only some of the keyboards have.

| Finger position   | Role                                      | Linux emits | macOS emits |
| ----------------- | ----------------------------------------- | ----------- | ----------- |
| Caps Lock         | **Control** — control codes, tmux, vim    | `Control_L` | `Control`   |
| left of space     | **Command** — copy/paste/tab/window       | `Super_L`   | `Command`   |
| two left of space | **Alt/Meta** — word motion, tmux direct   | `Alt_L`     | `Option`    |

Bottom-left corner is deliberately **not** an anchor: it is `Ctrl` on the XPS and
Pixelbook but `fn` on both MacBooks. That is the whole reason Caps carries Control.

## Why Command is Super on Linux

macOS has a modifier that is not Control (`Cmd`) sitting next to space. Linux does not.
Mapping the Linux next-to-space key to `Super` rather than `Control` keeps the two layers
apart exactly as macOS does:

 - **Control** never means "copy". It means SIGINT, tmux prefix, vim `<C-...>`. Identical
   on both platforms, reached from Caps on both platforms.
 - **Command** never reaches the tty. It is intercepted by the terminal emulator
   (iTerm2 / gnome-terminal) and by the window manager.

The price: Linux **GUI** toolkits hardcode `Ctrl` accelerators and will not accept
`Super-C`. In Firefox, Nautilus and friends, copy stays `Ctrl-C` — reached from Caps, like
every other `Ctrl` here. That is accepted, not worked around: they already use the
system clipboard, so the buffer is shared even when the key is not. Terminal applications
— the stated priority — are unaffected, because terminal emulators let their shortcuts be
rebound to `Super`, and nothing here substitutes `Super` for `Control` globally.

## Why Command cannot reach tmux or vim

A terminal only forwards what fits in a byte stream. `Cmd`/`Super` has no encoding, so
tmux and vim never see it — those bindings are consumed by the terminal emulator itself.
`Alt`/`Option` *does* encode (as an `ESC` prefix), so it is the modifier available to
in-terminal programs.

That is what satisfies "common actions must not be chained": tmux's frequent operations
bind to `Alt-<key>` directly with no `C-x` prefix. The `C-x` prefix survives for rare
operations only.

Requires the terminal to send Option as Meta:

 - gnome-terminal — on by default
 - kitty — on by default on Linux; `macos_option_as_alt both` in `kitty.conf` on macOS
 - iTerm2 — Profiles → Keys → Left/Right Option key → `Esc+` (no script can set this)

## Function row and Escape

`Esc` and `F1`–`F12` are treated as present everywhere:

 - Touchbar MBP — Settings → Keyboard → Touch Bar shows **F1–F12**, with `fn` for media.
 - Pixelbook — has a physical `Esc`; the top row emits `F1`–`F10` under Linux.

`F11`/`F12` are absent on the Pixelbook top row, so nothing load-bearing binds there.

## Navigation keys

These carry the same meaning in every layer, so muscle memory survives moving between the
shell, a pager, tmux scrollback and vim.

| Key             | Meaning              | shell (bash/zsh)    | tmux copy-mode   | vim      |
| --------------- | -------------------- | ------------------- | ---------------- | -------- |
| `Home`          | beginning of line    | `beginning-of-line` | `start-of-line`  | `0`      |
| `End`           | end of line          | `end-of-line`       | `end-of-line`    | `$`      |
| `Ctrl-Left`     | back one word        | `backward-word`     | `previous-word`  | `b`      |
| `Ctrl-Right`    | forward one word     | `forward-word`      | `next-word`      | `w`      |
| `Delete`        | delete char forward  | `delete-char`       | — (read-only)    | `x`      |
| `Ctrl-Delete`   | delete word forward  | `kill-word`         | — (read-only)    | `dw`     |
| `PageUp`        | page up              | enters scrollback   | `page-up`        | page up  |
| `PageDown`      | page down            | —                   | `page-down`      | page down|
| `Ctrl-Home`     | top of buffer        | —                   | `history-top`    | `gg`     |
| `Ctrl-End`      | bottom of buffer     | —                   | `history-bottom` | `G`      |

Word motion lands on the **start of the next word**, not the end of the current one, in all
four layers. zsh, vim (`w`) and tmux (`next-word`) already agreed; readline's `forward-word`
was the sole dissenter, so bash binds `vi-fword`/`vi-bword` rather than
`forward-word`/`backward-word`. `WORDCHARS` is pinned empty in zsh so a word ends at the
same character it does in bash — zsh's own default swallows a whole path in one press.

### Why these needed fixing at all

A terminal has four different ways to say `Home`, and which one it sends depends on the
emulator *and* on whether the cursor keys are in application mode:

| Form  | Bytes       | Sent by                                        |
| ----- | ----------- | ---------------------------------------------- |
| CSI   | `ESC [ H`   | kitty, alacritty; VTE in normal mode           |
| SS3   | `ESC O H`   | gnome-terminal/VTE and xterm in application mode |
| vt    | `ESC [ 1 ~` | what tmux and screen re-emit to programs inside |
| rxvt  | `ESC [ 7 ~` | rxvt and descendants                            |

`End` is the same four with `F`, `F`, `4~`, `8~`.

The layers did not agree:

 - **bash** binds the first three out of the box. Fine.
 - **zsh** binds exactly **one** — whichever `khome`/`kend` names for the current `TERM`.
   So `Home` worked in gnome-terminal and silently did nothing in kitty or alacritty, which
   send the CSI form that `TERM=xterm-256color` does not name. Verified, not theorised.
 - **tmux** copy-mode already binds `Home`/`End` correctly; no change was needed.
 - **vim** decodes all four under an `xterm` `TERM`, and all but SS3 under a `tmux`/`screen`
   `TERM` — where SS3 cannot arrive anyway, because tmux re-emits the vt form. So vim is
   correct in every combination that actually occurs, and is left alone. Adding
   `ESC`-prefixed maps to close a gap that cannot be reached would only make a bare
   `Escape` less responsive.

`Ctrl-Left`/`Ctrl-Right` have four forms of their own — `ESC [ 1 ; 5 D`, `ESC O 5 D`,
`ESC [ 5 D`, `ESC O d` — with the same split: oh-my-zsh binds the first, readline the first
and third. `Delete` is `ESC [ 3 ~` essentially everywhere, and `Ctrl-Delete` is `ESC [ 3 ; 5 ~`,
which readline does not ship at all.

The shell layer of `keys.yaml` (rendered to `.shell/.common.d/keys.sh`) binds every form in
both shells, which drops the dependency on
terminfo, on application mode, and on oh-my-zsh being installed: the key means the same
thing however it arrived and whatever framework is or is not present.

### The bash prompt had to be fixed for any of this to be visible

`.shell/.bashrc` built `PS1` with raw `\e[...m` colour escapes, unwrapped. readline counts
those as printable columns, so it believed the prompt was four columns wider than it is —
the `\e[0m` after the newline. `Home`, `End` and `Ctrl-Left`/`Ctrl-Right` moved the cursor
to logically correct positions that were drawn in the wrong column, and long lines redrew
over the prompt. Every escape is now wrapped in `\[ \]`.

zsh needed no equivalent: `%F{}`/`%f` are zero-width to zsh by definition, which is why only
the bash half of the two-line prompt carried the defect. The prompt renders identically
before and after; only readline's column arithmetic changed.

## Which layer owns each binding, and why

`keys.yaml` lists the bindings, grouped by layer. This is why each group sits in the layer it
does, and what breaks if it moves.

The rule underneath all of it: **a key is bound in the outermost layer that can still see
it.** A terminal emulator sees a keypress; tmux sees only the bytes the emulator forwards;
vim sees only the bytes tmux forwards. Binding something too far out makes it unreachable
to the layers inside; binding it too far in means an outer layer eats it first.

| Binding group | Layer (implemented in) | Why there, and not elsewhere |
| --- | --- | --- |
| Caps → Control; Alt/Super swap | `linux/apply.sh`, `macos/apply.sh` | The OS layer is the only one that can rewrite a *keysym*. Every layer above sees the result and needs no knowledge of it — doing this per-application would mean the same remap re-implemented in the emulator, tmux, the shells and vim, four places to drift. |
| Per-machine deviations | `linux/machines/<host>.sh` | The Pixelbook has no physical Super key at all, so it needs a different xkb rewrite. Keeping it hostname-selected means `apply.sh` stays the standard and the exception stays visibly an exception. |
| `Super-…` tab and window shortcuts | terminal (gnome-terminal via `linux/terminal.sh`; iTerm2 native) | `Super`/`Cmd` has **no byte encoding**, so it physically cannot reach tmux or vim — the emulator is the innermost layer that can see it. Binding it anywhere else would bind nothing. gnome-terminal and iTerm2 get the full set; kitty gets copy/paste only, since tmux windows cover tabs. |
| `Alt-…` tmux panes, windows, paging | tmux, root table (`bind -n`) | `Alt` *does* encode, as an `ESC` prefix, so it is the innermost modifier available to in-terminal programs. Root table rather than behind the `C-x` prefix because the requirement is that frequent operations are never chained. |
| `Alt-…` vim splits | vim (`.vim/keys.vim`) | tmux forwards these to vim only when the pane is running vim, so the same keystroke crosses both the pane and the split boundary. The vim half must exist independently: without it the keys still move tmux panes, which is a floor, not a break. |
| Edge handoff back to tmux | vim (`vimide#focus`, `vimide#resize` in `.vim/autoload/vimide.vim`) | Only vim knows whether it has a window in that direction, so only vim can decide to hand the keystroke back. tmux cannot: by the time it has forwarded the key it has no idea what vim did with it. Applies to focus and resize alike. |
| `Alt-Tab` pane cycling | tmux, root table, **no `pass: vim`** | The one focus key that is never forwarded. Every other focus binding depends on the inner layer cooperating; this one is the guarantee that holds when it does not. |
| Copy / paste — `Cmd-C`, `Cmd-V` | terminal (kitty, gnome-terminal; iTerm2 native) | Tier-1, so it is single modifier plus key, at the same finger position, on all three desktops. The emulator is the only layer that can reach the clipboard on *every* required terminal — OSC 52 would have let tmux and vim do it themselves, but VTE does not implement it, so on gnome-terminal that path is dead with no setting to revive it. |
| vim yank → clipboard | `.vimrc` hook, `vimide#clip` | A convenience, not the standard: `yy` pipes to `pbcopy`/`wl-copy`/`xclip` so a keyboard yank matches `Cmd-C`. Local only, and silent when no tool is installed — vim is built `-clipboard`, so there is nothing to fall back to. The tier-1 path never depends on it. |
| tmux mouse on, `Alt-m` to toggle | `.tmux.conf`, tmux layer | Mouse reporting is on for wheel scrollback, click-to-focus and drag-to-resize. The cost is that tmux takes a plain drag, so `Cmd-C` has no terminal selection to copy: hold `Shift` (`Option` in iTerm2) while dragging, or `Alt-m` to turn reporting off. |
| Selection highlight | `.tmux.conf` `mode-style`, `.vimrc` `Visual` | Two programs draw their own selections — tmux in copy-mode, vim in visual mode — and neither can read the other's colours. Written as colour *numbers* because the two disagree about what the colour names mean: tmux's `blue` is colour4, vim's `Blue` is colour12. |
| `Super-Tab` app switching | compositor (labwc `rc.xml`; GNOME via `linux/terminal.sh`); native on macOS | GNOME ships the switcher on `Super-Tab` *and* `Alt-Tab`. The `Alt` copy has to be released or it shadows tmux from outside, and pinning it to `Super` is also what makes Linux match macOS, where `Cmd-Tab` already switches applications. |
| `Home`/`End`/`Ctrl-arrow`/`Delete` in the shells | shell (`.shell/.common.d/keys.sh`) | Each layer decodes its own input, so there is no single place that can serve all of them. This is genuine duplication and is accepted: readline and ZLE cannot read tmux's or vim's tables. |
| `Home`/`End`/`Ctrl-arrow`/`Ctrl-Home`/`Ctrl-End` in scrollback | tmux, `table: copy` (both `copy-mode` tables) | Same reason, tmux's own tables. Both tables, because `mode-keys` follows `$EDITOR` and a box without vim lands in `copy-mode` rather than `copy-mode-vi`. |
| Prompt width | `.shell/.bashrc` | Not a binding, but the cursor keys draw in the wrong column without it — see below. |

### The conflicts this arrangement exists to avoid

Each of these is a case where two layers wanted the same key, and the fix was to decide
which layer owns it rather than to bind it twice and hope.

 - **gnome-terminal's tab keys vs tmux's window keys.** gnome-terminal ships
   `switch-to-tab-N` on `<Alt>N`, which is a head-on collision with `Alt-1`…`Alt-9` for tmux
   windows. `linux/terminal.sh` moves the terminal's tabs to `<Super>N`. The emulator is the
   outer layer, so if it kept `Alt` the keys would never reach tmux at all.
 - **GNOME Shell's dash vs the terminal's tabs.** Moving tabs to `Super-1`…`Super-9` then
   collides with GNOME Shell's `switch-to-application-N`, which is further out still and
   would win. `terminal.sh` releases those first. Order matters: outermost layer cleared
   first, then the next one in.
 - **`Alt-[` and `Alt-]` vs escape sequences.** Traditionally these transmit `ESC [` and
   `ESC ]`, the CSI and OSC introducers, which no program can tell from the start of a real
   escape sequence. tmux binds them anyway (swap pane up / down), relying on
   `extended-keys csi-u` to receive them unambiguously; treat them as best-effort and never
   put anything essential there. Previous/next window stays on `Alt-,` / `Alt-.`.
 - **tmux pane focus vs vim split focus.** Both want `Alt-h/j/k/l`. tmux owns the key and
   forwards it when the pane is running vim (`is_vim`), which is vim-tmux-navigator
   behaviour without the plugin.
 - **Forwarding into vim is a one-way door, and that trapped focus.** Once tmux has decided
   the pane is running vim, the keystroke is gone. If vim is already in its leftmost split,
   `<C-w>h` is a silent no-op — so `Alt-h` was consumed and did nothing, and there was no
   way back out to the tmux pane on that side. Only vim can detect this, because only vim
   knows whether the window number changed; `s:VimIdeFocus` compares `winnr()` before and
   after and, if it did not move, issues `tmux select-pane` itself. That is a tmux
   *command*, not a keystroke, so it cannot be re-forwarded and cannot loop.
 - **Resize was trapped the same way, and the obvious test for it is wrong.** `Alt-Shift-L`
   in a vim with no split beside it was a silent no-op for the same reason. The tempting
   fix — resize, then check whether the dimension changed — passes on three directions and
   fails on the fourth: with a single window `<C-w>-` genuinely *does* shrink it, leaving
   the freed row blank, so the height changes, the handoff never fires, and repeated
   presses shrink the lone window inside a full-size pane. `s:VimIdeResize` therefore asks
   `winnr('h')`/`winnr('j')` whether a neighbour exists in that axis *before* resizing, and
   hands the key to `tmux resize-pane` when there is none.
 - **GNOME's `Alt-Tab` vs tmux's pane cycling.** GNOME binds `switch-applications` to both
   `<Super>Tab` and `<Alt>Tab`; the `Alt` copy is the outer layer and wins, so `Alt-Tab`
   never reaches the terminal. `terminal.sh` pins the switcher to `Super-Tab` alone. This
   is the `Alt`/`Super` split applied to one more key: `Super` switches applications,
   `Alt` switches panes inside one — the same distinction macOS already makes for free.
 - **Copy/paste is tier-1, so it gets one gesture and no chords.** `Cmd-C` / `Super-C` and
   `Cmd-V` / `Super-V`, single modifier plus key, at the key left of the space bar on every
   machine. `Ctrl-Shift-C` is a chord and was rejected on that basis alone; it is also a
   *different* finger position from macOS, which is the thing this standard exists to
   remove. Every target writes the same `CLIPBOARD` selection that GTK apps use.
 - **Three grabs sit on top of the terminal on GNOME and had to be released.** The
   compositor takes a key before the focused window sees it, so a grabbed accelerator looks
   bound and does nothing, with no error anywhere. `Super-A` is the app grid, `Super-N`
   focuses the last notification, and `Super-V` has shipped as the message tray in some
   versions. `linux/terminal.sh` releases all three; the `Super-V` release is unconditional
   rather than conditional, because a grab there means paste is dead machine-wide.
 - **`Cmd-C` vs the mouse.** `Cmd-C` can only copy what the *terminal* has selected. With
   tmux mouse reporting on, which is the default here, tmux consumes a plain drag and the
   terminal's selection stays empty. `Shift`-drag (`Option`-drag in iTerm2) bypasses tmux
   and makes a terminal selection; `Alt-m` turns reporting off entirely when a plain drag is
   wanted.
 - **The earlier OSC 52 design, and why it is gone.** tmux and vim were made to put their
   own selections on the clipboard by writing OSC 52 to the terminal. It worked on iTerm2,
   alacritty and kitty and was silently dead on gnome-terminal: **VTE has never implemented
   OSC 52 and offers no setting to enable it.** A mechanism that fails invisibly on a
   required terminal is worse than no mechanism. Piping to `xclip` instead would have worked
   locally and failed over ssh, which is the case tmux exists for — whereas a terminal-side
   selection is made by the *local* terminal out of glyphs already on screen, so it works
   over ssh with nothing installed on the far end.
 - **labwc takes `Super-A` and `Super-T` before the terminal.** On a labwc session they are
   maximize and launch-kitty, so gnome-terminal's select-all and new-tab never fire there.
   `CHEATSHEET.md` lists every such case under "Shadowed keys"; kitty binds neither, so the
   tier-1 labwc + kitty pairing is unaffected.
 - **Supported terminals.** See the tiers at the top. A behaviour that cannot be made to work
   on all three tier-1 terminals does not ship — that rule is what removed OSC 52.
 - **`Alt-Tab` is deliberately excluded from the `is_vim` forwarding.** Every other focus
   key trusts the inner layer to cooperate. This one does not, on purpose: it is the key
   that still works against an unconfigured vim, an old vim, or any program that swallows
   `Alt`. One binding in the set has to be unconditional or "focus is trapped" is always
   one misconfigured pane away.
 - **tmux scrollback vs a program's own pager.** Both want `PageUp`. tmux owns it and
   forwards it whenever the pane is running something that pages its own content — tested as
   `alternate_on` **or** a command-name match, because `LESS="-EXFR"` in
   `.shell/.common.d/home.sh` keeps `less` off the alternate screen.
 - **`Ctrl-Left`/`Ctrl-Right` are deliberately *not* bound in tmux's root table**, so they
   pass through untouched to the shell or vim. Word motion is a line-editing operation and
   belongs to whatever is reading the line.
 - **The rxvt form of `Ctrl-Right` is bound in the shells and nowhere else.** `ESC [ 5 C` is
   safe for readline and ZLE, but vim decodes the tail as `5C` — change five lines — which
   destroys the buffer. It is bound where it is harmless and left alone where it is not.
 - **`Alt-Left`/`Alt-Right` remain readline word-motion defaults in bash.** tmux takes those
   keys before bash ever sees them, so the binding is unreachable inside tmux and harmless
   outside it, where there are no panes to move between. Left alone rather than unbound.

### Two things vim needs that look like they should be symmetrical, and are not

 - `Alt`+letter arrives as a bare `ESC` prefix, which vim does **not** decode. Each one is
   declared with `set <M-h>=\<Esc>h` before it can be mapped.
 - `Alt`+arrow arrives as the xterm CSI form `ESC [ 1 ; 3 <letter>`, which vim decodes
   natively. Declaring it is not redundant but an **error**: `set <M-Up>=` is `E518`,
   because that syntax only accepts keys vim carries as termcap entries.

## Applying

```sh
scripts/keyboard/linux/apply.sh          # GNOME/Wayland and X11 — calls terminal.sh
scripts/keyboard/macos/apply.sh          # hidutil + a LaunchAgent so it survives reboot
```

`install.sh` runs the right one through `scripts/install.d/30-keyboard.sh`; run it by hand
to re-apply. One command per platform. On Linux `apply.sh` does the xkb modifier remap and then runs
`linux/terminal.sh` for the emulator shortcuts; run `terminal.sh` on its own only when
re-applying emulator bindings without touching the layout.

Both are idempotent, self-guarding, and no-op on the wrong platform. Neither installs
packages (that is `scripts/pkgs/deb.sh`) and neither writes a file into `$HOME`: the kitty
and labwc configs and the macOS LaunchAgent are repo files that `install.sh` links in
(`LINKS` in `scripts/lib.sh`). `terminal.sh` only applies the generated `gnome-keys.sh`
through gsettings.

On a labwc session `apply.sh` changes nothing: it only knows GNOME's gsettings and X11's
setxkbmap. labwc reads its xkb options from `.config/labwc/environment`.

After running either, restart tmux (`tmux kill-server`) — `.tmux.conf` is read at server
start, and a running server keeps the bindings it had.

Per-machine deviations live in `scripts/keyboard/linux/machines/<name>.sh`, selected by
hostname, falling back to nothing. The Pixelbook needs one because it has no physical
Super key at all — see `machines/pixelbook.sh`.
