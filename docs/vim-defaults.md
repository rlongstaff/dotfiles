# vim defaults

vim's own keys, as shipped: no mapping in this repo changes them unless a row says so.
Every key this repo *does* bind, in vim and every other layer, is in `keyboard-cheatsheet.md`,
generated from `keys.yaml`.

Notation: `Ctrl-x`, `Alt-x` (Option on macOS), `Shift-x`.

## Buffers

vim defaults; no custom buffer mappings exist yet.

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
repo's fast path for focus and resize (see `keyboard-cheatsheet.md`); everything here is default vim.

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

tmux panes are not vim, but vim splits live inside them and share the Alt keys. The
full set, including which keys tmux forwards into vim, is in `keyboard-cheatsheet.md`.

## Cursor movement — Normal mode

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

## Editing — Normal mode

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

## Editing — Insert mode

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
| paste (`Cmd-V`/`Super-V`) | bracketed paste — no auto-indent staircase, no mapping needed |

## Command-line mode (`:`, `/`, `?`)

| Key | Does |
| --- | ---- |
| `:` | enter command-line mode |
| `/pattern`, `?pattern` | search forward / backward |
| `n` / `N` | repeat last search, same / opposite direction |
| `Ctrl-a` / `Ctrl-e` | start / end of the command line (vim default; this repo's `Ctrl-a` / `Ctrl-e` maps cover Normal, Insert and Visual only) |
| `Tab` | complete command/filename |
| Up / Down or `Ctrl-p` / `Ctrl-n` | previous / next command-line history entry |
