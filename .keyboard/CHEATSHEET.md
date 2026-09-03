# Keyboard cheatsheet

Every binding in the standard, and the file that implements it. See `README.md` for why the
layers are split the way they are.

## The three anchors

The only key positions present on all six target keyboards. Everything else is derived.

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
| **Control** | signals, tmux prefix, vim `<C-…>` | copy/paste                          |

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

**Linux GUI apps are the exception.** GTK and Qt hardcode `Ctrl` accelerators and will not
accept `Super-C`. In Firefox and Nautilus, copy stays `Caps-C`.

## Alt — tmux, unprefixed

Frequent operations are never chained. `C-x` survives for the rare ones.

| Key            | Does                          |
| -------------- | ----------------------------- |
| `Alt-\`        | split vertical                |
| `Alt--`        | split horizontal              |
| `Alt-z`        | zoom pane                     |
| `Alt-w`        | kill pane                     |
| `Alt-n`        | new window                    |
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

| Gesture | Does | Who does it |
| ------- | ---- | ----------- |
| drag with the mouse | selects **and copies** to the system clipboard | tmux, or vim |
| double-click / triple-click | copies word / line | tmux |
| `y` or `Enter` in scrollback | copies the selection | tmux copy-mode |
| `y` in vim | copies to the system clipboard too | vim |
| `Cmd-C` | copies the **terminal's** selection | terminal emulator |
| `Cmd-V` | pastes | terminal emulator |
| `Shift`-drag | selects with the *terminal*, bypassing tmux and vim | terminal emulator |
| `C-x` `]` | pastes tmux's own buffer | tmux |

**Selecting is copying.** `Cmd-C` cannot reach tmux or vim — `Cmd` has no byte encoding — so
waiting for it would mean the key never arrives. Instead the selection lands on the system
clipboard the instant it is made, and `Cmd-C` stays bound for the case where the terminal
owns the selection.

**It works over ssh.** Copying travels as an OSC 52 escape sequence to whatever terminal is
attached, so a selection made in a remote tmux or vim lands on the *local* clipboard. No
`xclip` on the far end, nothing forwarded.

`Shift`-drag is the escape hatch: it bypasses mouse reporting entirely and gives the
terminal's own selection, which is what `Cmd-C` copies. Use it when you want a rectangle of
the screen rather than what tmux or vim thinks you selected.

Deletes never touch the clipboard — only yanks do. In vim, a mouse selection leaves vim's
own registers untouched, so selecting a target to paste over does not destroy the text
about to be pasted.

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

## Where each binding is implemented

| Binding group                | File                                  |
| ---------------------------- | ------------------------------------- |
| Caps→Control, Alt/Super swap | `.keyboard/linux/apply.sh`, `.keyboard/macos/apply.sh` |
| Command (Super) shortcuts    | `.keyboard/linux/terminal.sh`; iTerm2 native on macOS |
| Alt — tmux, focus, resize, paging | `.tmux.conf`                     |
| `Alt-Tab` pane cycling       | `.tmux.conf`; GNOME released in `.keyboard/linux/terminal.sh` |
| Home/End/Ctrl-arrow in copy-mode | `.tmux.conf`                      |
| Alt — vim splits             | `.vimrc`                              |
| Copy → clipboard (OSC 52)    | `.tmux.conf` and `.vimrc`             |
| Selection highlight          | `.tmux.conf` `mode-style`, `.vimrc` `Visual` |
| vim edge handoff back to tmux| `.vimrc` (`s:VimIdeFocus`, `s:VimIdeResize`) |
| Line editing in the shells   | `.shell/.common.d/keys.sh`            |
| Prompt width (readline)      | `.shell/.bashrc`                      |

## Two settings no script can set

 - **iTerm2** — Profiles → Keys → Left/Right Option key → `Esc+`. Without this, Option never
   reaches tmux or vim and half this sheet is dead.
 - **Touch Bar MBP** — Settings → Keyboard → Touch Bar shows **F1–F12**, `fn` for media.
