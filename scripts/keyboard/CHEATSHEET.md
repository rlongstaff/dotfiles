# Keyboard cheatsheet

Every binding in the standard, and the file that implements it. See `README.md` for why the
layers are split the way they are.

## The three modifier anchors

The only *modifier* positions in the same place on all six target keyboards. Every binding
below is expressed in terms of these three.

| Finger position       | Is         | Linux keysym | macOS   |
| --------------------- | ---------- | ------------ | ------- |
| Caps Lock             | **Control**| `Control_L`  | Control |
| left of space         | **Command**| `Super_L`    | Command |
| two left of space     | **Alt**    | `Alt_L`      | Option  |

Bottom-left corner is **not** an anchor — `Ctrl` on the XPS and Pixelbook, `fn` on both
MacBooks. That is why Caps carries Control.

## Who owns which modifier

| Modifier    | Owned by                        | Never used for                       |
| ----------- | ------------------------------- | ------------------------------------ |
| **Command** | terminal emulator, window manager | anything inside tmux or vim — it has no byte encoding and cannot get there |
| **Alt**     | tmux, and vim splits             | terminal-emulator shortcuts          |
| **Control** | signals, tmux prefix, vim `<C-…>` | copy/paste **in a terminal** — GUI apps still use `Ctrl-C`/`Ctrl-V` |

## Command — terminal and window (never reaches tmux or vim)

| Key             | Does            |
| --------------- | --------------- |
| `Cmd-C` / `Cmd-V` | copy / paste  |
| `Cmd-A`         | select all      |
| `Cmd-F`         | find            |
| `Cmd-T` / `Cmd-W` | new / close tab |
| `Cmd-N`         | new window      |
| `Cmd-1` … `Cmd-9` | tab N         |
| `Cmd-Left` / `Cmd-Right` | previous / next tab |
| `Cmd-Tab` / `Cmd-Shift-Tab` | switch application — the OS, not the terminal |

`Cmd` is `Super` on Linux and `Command` on macOS, both at the key left of space.

**Copy and paste are on all five terminals; the rest depend on what the emulator has.**
gnome-terminal and iTerm2 get the whole table. kitty gets copy/paste plus tabs and windows,
alacritty gets copy/paste and windows (it has no tabs), xterm gets copy/paste only. Tabs and
windows are reachable through tmux anyway, which is why the frequent operations live there.

**Linux GUI apps are the exception, deliberately.** GTK and Qt hardcode `Ctrl` accelerators
and will not accept `Super-C`. Firefox, Nautilus and the rest keep `Ctrl-C` / `Ctrl-V` —
`Ctrl` reached from Caps, like everywhere else. They already use the system clipboard, so
the buffer is shared even where the key is not.

## Alt — tmux, unprefixed

Frequent operations are never chained. `C-x` survives for the rare ones.

| Key            | Does                          |
| -------------- | ----------------------------- |
| `Alt-\`        | split vertical                |
| `Alt--`        | split horizontal              |
| `Alt-z`        | zoom pane                     |
| `Alt-w`        | kill pane                     |
| `Alt-n`        | new window                    |
| `Alt-m`        | toggle tmux mouse reporting   |
| `Alt-,` / `Alt-.` | previous / next window     |
| `Alt-1` … `Alt-9` | window N                   |

`Alt-[` and `Alt-]` are **unusable** — they transmit `ESC [` and `ESC ]`, the CSI and OSC
introducers, which no program can tell from a real escape sequence. Hence `,` and `.`.

## Alt — focus and resize, shared between tmux panes and vim splits

One keystroke crosses both boundaries. In a pane running vim the key is forwarded to vim;
anywhere else it moves the tmux pane.

| Key | Focus | | Key | Resize |
| --- | ----- |-| --- | ------ |
| `Alt-h` / `Alt-Left`   | pane/split left  | | `Alt-H` / `Alt-Shift-Left`  | narrow |
| `Alt-j` / `Alt-Down`   | pane/split down  | | `Alt-J` / `Alt-Shift-Down`  | lengthen |
| `Alt-k` / `Alt-Up`     | pane/split up    | | `Alt-K` / `Alt-Shift-Up`    | shorten |
| `Alt-l` / `Alt-Right`  | pane/split right | | `Alt-L` / `Alt-Shift-Right` | widen |

Letters and arrows are interchangeable everywhere, not only in vim's normal mode.

At the edge of vim's split layout, **both** focus and resize hand back to tmux rather than
stopping. `Alt-l` in vim's rightmost split moves to the tmux pane on the right, and
`Alt-Shift-L` in a vim with no split beside it widens the tmux pane. Without the handoff
the keystroke is swallowed by vim and does nothing — for focus that means being stuck in
the pane; for resize it means a key that quietly no-ops.

## Alt-Tab — cycle panes, the guaranteed way out

`Cmd-Tab` switches applications; `Alt-Tab` is the same gesture one layer in.

| Key             | Does                        |
| --------------- | --------------------------- |
| `Alt-Tab`       | next tmux pane, wrapping    |
| `Alt-Shift-Tab` | previous tmux pane, wrapping|

Unlike `Alt-h/j/k/l`, this is **never** forwarded to the program in the pane. It always
moves the tmux pane, whatever is running — so focus can never be trapped, even in a vim
that predates this config or a program that eats Alt keys.

On Linux this needs `terminal.sh`, which pins GNOME's application switcher to `Super-Tab`
alone; GNOME ships it on `Super-Tab` **and** `Alt-Tab`, and the second one shadows tmux.
macOS needs nothing: `Cmd-Tab` is already the switcher and `Option-Tab` is already free.

## Copy and paste

**One gesture, one modifier, one clipboard, three desktops.**

| Key | Does | Where |
| --- | ---- | ----- |
| `Cmd-C` / `Super-C` | copy the selection | every terminal, all three desktops |
| `Cmd-V` / `Super-V` | paste | every terminal, all three desktops |
| drag with the mouse | make the selection | shell pane |
| `Alt-m` | toggle tmux mouse reporting | tmux |

`Cmd` on macOS and `Super` on Linux are the **same physical key** — the one left of the
space bar. Same finger, same result, on GNOME/Wayland, fluxbox/X11 and macOS.

Firefox, Nautilus and other desktop applications are untouched and keep `Ctrl-C` / `Ctrl-V`.
Nothing rebinds Control; `Super` is *added* inside terminals, not substituted for anything.

**The mouse is off in tmux by default, and that is what makes copy work.** `Cmd-C` copies
the *terminal's* selection. If tmux owns the mouse, a drag makes a tmux selection instead,
the terminal's stays empty, and `Cmd-C` silently copies nothing. With mouse reporting off,
a plain drag is a terminal selection and the tier-1 gesture just works.

`Alt-m` turns mouse reporting back on when you want wheel scrollback, click-to-focus or
drag-to-resize, and off again. While it is on, hold `Shift` (`Option` in iTerm2) to select.
`PageUp` reaches scrollback either way.

Inside a vim pane vim owns the mouse, so `Shift`-drag there.

`yy` in vim also reaches the clipboard when `pbcopy`, `wl-copy` or `xclip` is installed —
a convenience, not part of the standard. It is local-only and silent when no tool is there;
`Cmd-C` is the path that always works.

## Line editing — identical in bash, zsh, tmux copy-mode and vim

| Key           | Does                 | shell               | tmux copy-mode   | vim  |
| ------------- | -------------------- | ------------------- | ---------------- | ---- |
| `Home`        | beginning of line    | `beginning-of-line` | `start-of-line`  | `0`  |
| `End`         | end of line          | `end-of-line`       | `end-of-line`    | `$`  |
| `Ctrl-Left`   | back one word        | `backward-word`     | `previous-word`  | `b`  |
| `Ctrl-Right`  | forward one word     | `forward-word`      | `next-word`      | `w`  |
| `Delete`      | delete char forward  | `delete-char`       | — read-only      | `x`  |
| `Ctrl-Delete` | delete word forward  | `kill-word`         | — read-only      | `dw` |
| `PageUp`      | page up              | enters scrollback   | `page-up`        | page up |
| `PageDown`    | page down            | —                   | `page-down`      | page down |
| `Ctrl-Home`   | top of buffer        | —                   | `history-top`    | `gg` |
| `Ctrl-End`    | bottom of buffer     | —                   | `history-bottom` | `G`  |

Word motion stops at the **start of the next word** in all four layers.

`PageUp` in a plain shell pane enters tmux scrollback; in anything that pages its own
content (`vim`, `less`, `man`, `top`) the key is passed straight through.

## vim, beyond the shared set

| Key                    | Does              |
| ---------------------- | ----------------- |
| `Ctrl-Up` / `Ctrl-Down`| half-page scroll  |

## tmux prefix — `C-x`, for the rare operations

| Key         | Does             |
| ----------- | ---------------- |
| `C-x` `\`   | split vertical   |
| `C-x` `-`   | split horizontal |
| `C-x` `]`   | paste tmux's own copy-mode buffer |

## Where each binding is implemented

| Binding group                | File                                  |
| ---------------------------- | ------------------------------------- |
| Caps→Control, Alt/Super swap | `scripts/keyboard/linux/apply.sh`, `scripts/keyboard/macos/apply.sh` |
| Command (Super) shortcuts    | `scripts/keyboard/linux/terminal.sh`; iTerm2 native on macOS |
| Alt — tmux, focus, resize, paging | `.tmux.conf`                     |
| `Alt-Tab` pane cycling       | `.tmux.conf`; GNOME released in `scripts/keyboard/linux/terminal.sh` |
| Home/End/Ctrl-arrow in copy-mode | `.tmux.conf`                      |
| Alt — vim splits             | `.vimrc`                              |
| `Super-C` / `Super-V` copy/paste | `scripts/keyboard/linux/terminal.sh`; iTerm2 native |
| tmux mouse off + `Alt-m` toggle | `.tmux.conf`                          |
| Selection highlight          | `.tmux.conf` `mode-style`, `.vimrc` `Visual` |
| vim edge handoff back to tmux| `.vimrc` (`s:VimIdeFocus`, `s:VimIdeResize`) |
| vim yank → clipboard         | `.vimrc` (`s:VimIdeClip`)             |
| Line editing in the shells   | `.shell/.common.d/keys.sh`            |
| Prompt width (readline)      | `.shell/.bashrc`                      |

## Applying it

```sh
scripts/keyboard/linux/apply.sh    # modifier remap, then terminal.sh for the emulator shortcuts
scripts/keyboard/macos/apply.sh    # Caps → Control, kept across reboots by a LaunchAgent
tmux kill-server                   # .tmux.conf is read at server start
```

`install.sh` runs the platform's `apply.sh` for you; the lines above re-apply it.

## Two settings no script can set

 - **iTerm2** — Profiles → Keys → Left/Right Option key → `Esc+`. Without this, Option never
   reaches tmux or vim and half this sheet is dead.
 - **Touch Bar MBP** — Settings → Keyboard → Touch Bar shows **F1–F12**, `fn` for media.
