<!-- GENERATED from keys.yaml by render.sh. Edit the yaml, not this file. -->

# Keyboard cheatsheet

Every binding in the dotfiles, generated from `keys.yaml`. Why each key
lives where it does is in `keyboard.md`; vim's own defaults are in `vim-defaults.md`.

**Capture order.** A keystroke goes `os -> compositor -> terminal -> tmux -> shell | vim`,
and the first layer that binds it wins. **Bold** marks that layer. `→ vim` / `→ pager`
means tmux forwards the key when the pane runs vim / a pager. "released" means the layer
explicitly lets the key through. ~~Struck~~ means an earlier layer takes the key first.

Keys are spelled `ctrl alt shift super`. Super is Cmd on macOS, and the key left of the
space bar on every machine; alt is Option.

## Capture chain

| key | os | compositor | terminal | tmux | shell | vim |
| --- | --- | --- | --- | --- | --- | --- |
| `capslock` | **becomes ctrl** |  |  |  |  |  |
| `alt` | **swapped with super, so the key left of space is super (Linux)** |  |  |  |  |  |
| `super+tab` |  | **next window / application** |  |  |  |  |
| `shift+super+tab` |  | **previous window / application** |  |  |  |  |
| `super+a` |  | **toggle maximize (labwc); released** | ~~select all~~ |  |  |  |
| `super+t` |  | **launch kitty (labwc)** | ~~new tab~~ |  |  |  |
| `super+l` |  | **lock screen (labwc)** |  |  |  |  |
| `XF86MonBrightnessUp` |  | **brightness up** |  |  |  |  |
| `XF86MonBrightnessDown` |  | **brightness down** |  |  |  |  |
| `XF86AudioRaiseVolume` |  | **volume up** |  |  |  |  |
| `XF86AudioLowerVolume` |  | **volume down** |  |  |  |  |
| `XF86AudioMute` |  | **mute toggle** |  |  |  |  |
| `super+1` |  | released | **tab 1** |  |  |  |
| `super+2` |  | released | **tab 2** |  |  |  |
| `super+3` |  | released | **tab 3** |  |  |  |
| `super+4` |  | released | **tab 4** |  |  |  |
| `super+5` |  | released | **tab 5** |  |  |  |
| `super+6` |  | released | **tab 6** |  |  |  |
| `super+7` |  | released | **tab 7** |  |  |  |
| `super+8` |  | released | **tab 8** |  |  |  |
| `super+9` |  | released | **tab 9** |  |  |  |
| `super+n` |  | released | **new window** |  |  |  |
| `super+m` |  | **GNOME message tray, moved here off super+v (paste)** |  |  |  |  |
| `alt+mouse-left` |  | **drag window frame to move (labwc)** |  |  |  |  |
| `alt+mouse-right` |  | **drag window frame to resize (labwc)** |  |  |  |  |
| `super+wheel` |  | **zoom in / out (labwc magnifier)** |  |  |  |  |
| `super+c` |  |  | **copy** |  |  |  |
| `super+v` |  |  | **paste** |  |  |  |
| `super+f` |  |  | **find** |  |  |  |
| `super+w` |  |  | **close tab** |  |  |  |
| `super+left` |  |  | **previous tab** |  |  |  |
| `super+right` |  |  | **next tab** |  |  |  |
| `alt+0` |  |  | released |  |  |  |
| `f10` |  |  | released |  |  | **step over** |
| `f11` |  |  | released |  |  | **step into** |
| `ctrl+x` |  |  |  | **tmux prefix** |  |  |
| `alt+m` |  |  |  | **toggle mouse reporting (on by default; shift+drag selects for the terminal)** |  |  |
| `alt+\` |  |  |  | **split right** |  |  |
| `alt+-` |  |  |  | **split below** |  |  |
| `alt+z` |  |  |  | **zoom pane** |  |  |
| `alt+enter` |  |  |  | **zoom pane** |  |  |
| `alt+[` |  |  |  | **swap pane up** |  |  |
| `alt+]` |  |  |  | **swap pane down** |  |  |
| `alt+w` |  |  |  | **kill pane** |  |  |
| `\` |  |  |  | after prefix: split right (prefix, old habit) |  |  |
| `-` |  |  |  | after prefix: split below (prefix, old habit) |  |  |
| `"` |  |  |  | released |  |  |
| `%` |  |  |  | released |  |  |
| `alt+n` |  |  |  | **new window** |  |  |
| `alt+,` |  |  |  | **previous window** |  |  |
| `alt+.` |  |  |  | **next window** |  |  |
| `alt+1` |  |  |  | **window 1** |  |  |
| `alt+2` |  |  |  | **window 2** |  |  |
| `alt+3` |  |  |  | **window 3** |  |  |
| `alt+4` |  |  |  | **window 4** |  |  |
| `alt+5` |  |  |  | **window 5** |  |  |
| `alt+6` |  |  |  | **window 6** |  |  |
| `alt+7` |  |  |  | **window 7** |  |  |
| `alt+8` |  |  |  | **window 8** |  |  |
| `alt+9` |  |  |  | **window 9** |  |  |
| `alt+h` |  |  |  | **→ vim: focus left** |  | split left (else tmux pane) |
| `alt+j` |  |  |  | **→ vim: focus down** |  | split down (else tmux pane) |
| `alt+k` |  |  |  | **→ vim: focus up** |  | split up (else tmux pane) |
| `alt+l` |  |  |  | **→ vim: focus right** |  | split right (else tmux pane) |
| `alt+left` |  |  |  | **→ vim: focus left** |  | split left (else tmux pane) |
| `alt+down` |  |  |  | **→ vim: focus down** |  | split down (else tmux pane) |
| `alt+up` |  |  |  | **→ vim: focus up** |  | split up (else tmux pane) |
| `alt+right` |  |  |  | **→ vim: focus right** |  | split right (else tmux pane) |
| `alt+tab` |  |  |  | **next pane, never forwarded (the guaranteed way out)** |  |  |
| `alt+shift+tab` |  |  |  | **previous pane, never forwarded** |  |  |
| `alt+shift+h` |  |  |  | **→ vim: narrow** |  | narrow (else tmux pane) |
| `alt+shift+j` |  |  |  | **→ vim: lengthen** |  | lengthen (else tmux pane) |
| `alt+shift+k` |  |  |  | **→ vim: shorten** |  | shorten (else tmux pane) |
| `alt+shift+l` |  |  |  | **→ vim: widen** |  | widen (else tmux pane) |
| `alt+shift+left` |  |  |  | **→ vim: narrow** |  | narrow (else tmux pane) |
| `alt+shift+down` |  |  |  | **→ vim: lengthen** |  | lengthen (else tmux pane) |
| `alt+shift+up` |  |  |  | **→ vim: shorten** |  | shorten (else tmux pane) |
| `alt+shift+right` |  |  |  | **→ vim: widen** |  | widen (else tmux pane) |
| `pageup` |  |  |  | **→ pager: enter scrollback in a shell pane; passed through to pagers and vim** |  |  |
| `ctrl+home` |  |  |  | copy-mode: scrollback top |  |  |
| `ctrl+end` |  |  |  | copy-mode: scrollback bottom |  |  |
| `ctrl+left` |  |  |  | copy-mode: previous word | **previous word start** |  |
| `ctrl+right` |  |  |  | copy-mode: next word | **next word start** |  |
| `]` |  |  |  | after prefix: paste tmux's own copy-mode buffer (prefix) |  |  |
| `home` |  |  |  |  | **start of line** |  |
| `ctrl+a` |  |  |  |  | **start of line** | ~~start of line~~ |
| `end` |  |  |  |  | **end of line** |  |
| `ctrl+e` |  |  |  |  | **end of line** | ~~end of line~~ |
| `delete` |  |  |  |  | **delete char forward** |  |
| `ctrl+delete` |  |  |  |  | **delete word forward** |  |
| `enter` |  |  |  |  |  | **clear search highlight** |
| `ctrl+up` |  |  |  |  |  | **half page up** |
| `ctrl+down` |  |  |  |  |  | **half page down** |
| `ctrl+t` |  |  |  |  |  | **toggle NERDTree** |
| `f12` |  |  |  |  |  | **go to definition (else tag jump)** |
| `ctrl+shift+f12` |  |  |  |  |  | **go to declaration (else gD)** |
| `ctrl+f12` |  |  |  |  |  | **go to implementation** |
| `shift+f12` |  |  |  |  |  | **list references** |
| `alt+f12` |  |  |  |  |  | **hover docs (else K)** |
| `f2` |  |  |  |  |  | **rename symbol** |
| `f5` |  |  |  |  |  | **start / continue** |
| `shift+f5` |  |  |  |  |  | **stop and close debugger** |
| `ctrl+f5` |  |  |  |  |  | **restart** |
| `f9` |  |  |  |  |  | **toggle breakpoint** |
| `shift+f11` |  |  |  |  |  | **step out** |
| `f8` |  |  |  |  |  | **evaluate under cursor** |

## Shadowed keys

Bound in a later layer, but an earlier layer takes the key first. On a desktop
that does not run the earlier app (labwc vs GNOME, say) there is no conflict.

- `super+a`: compositor (toggle maximize (labwc); released) before terminal (select all)
- `super+t`: compositor (launch kitty (labwc)) before terminal (new tab)
- `ctrl+a`: shell (start of line) before vim (start of line)
- `ctrl+e`: shell (end of line) before vim (end of line)

## OS modifier remap

Rendered to / applied by: scripts/keyboard/linux/apply.sh (xkb), scripts/keyboard/macos/apply.sh (hidutil)

| key | action | apps | note |
| --- | --- | --- | --- |
| `capslock` | becomes ctrl |  | Linux xkb ctrl:nocaps; macOS hidutil + LaunchAgent |
| `alt` | swapped with super, so the key left of space is super (Linux) |  | xkb altwin:swap_lalt_lwin; the Pixelbook uses machines/pixelbook.sh instead |

## Window manager / desktop

Rendered to / applied by: labwc .config/labwc/rc.xml; GNOME Shell via scripts/keyboard/linux/terminal.sh

| key | action | apps | note |
| --- | --- | --- | --- |
| `super+tab` | next window / application | labwc, gnome | GNOME ships this on alt+tab too; pinning it to super+tab frees alt+tab for tmux |
| `shift+super+tab` | previous window / application | labwc, gnome |  |
| `super+a` | toggle maximize (labwc) | labwc |  |
| `super+t` | launch kitty (labwc) | labwc |  |
| `super+l` | lock screen (labwc) | labwc |  |
| `XF86MonBrightnessUp` | brightness up | labwc |  |
| `XF86MonBrightnessDown` | brightness down | labwc |  |
| `XF86AudioRaiseVolume` | volume up | labwc |  |
| `XF86AudioLowerVolume` | volume down | labwc |  |
| `XF86AudioMute` | mute toggle | labwc |  |
| `super+1` | released from GNOME's dash so the terminal gets tab 1 | gnome |  |
| `super+2` | released from GNOME's dash so the terminal gets tab 2 | gnome |  |
| `super+3` | released from GNOME's dash so the terminal gets tab 3 | gnome |  |
| `super+4` | released from GNOME's dash so the terminal gets tab 4 | gnome |  |
| `super+5` | released from GNOME's dash so the terminal gets tab 5 | gnome |  |
| `super+6` | released from GNOME's dash so the terminal gets tab 6 | gnome |  |
| `super+7` | released from GNOME's dash so the terminal gets tab 7 | gnome |  |
| `super+8` | released from GNOME's dash so the terminal gets tab 8 | gnome |  |
| `super+9` | released from GNOME's dash so the terminal gets tab 9 | gnome |  |
| `super+a` | released from GNOME's app grid (terminal select-all) | gnome |  |
| `super+n` | released from GNOME's notification focus (terminal new window) | gnome |  |
| `super+m` | GNOME message tray, moved here off super+v (paste) | gnome |  |
| `alt+mouse-left` | drag window frame to move (labwc) |  |  |
| `alt+mouse-right` | drag window frame to resize (labwc) |  |  |
| `super+wheel` | zoom in / out (labwc magnifier) |  |  |

## Terminal emulator (super never reaches the tty)

Rendered to / applied by: kitty .config/kitty/keys.conf; gnome-terminal via linux/terminal.sh; iTerm2 native

| key | action | apps | note |
| --- | --- | --- | --- |
| `super+c` | copy | kitty, gnome-terminal, iterm2 |  |
| `super+v` | paste | kitty, gnome-terminal, iterm2 |  |
| `super+a` | select all | gnome-terminal, iterm2 |  |
| `super+f` | find | gnome-terminal, iterm2 |  |
| `super+t` | new tab | gnome-terminal, iterm2 |  |
| `super+w` | close tab | gnome-terminal, iterm2 |  |
| `super+n` | new window | gnome-terminal, iterm2 |  |
| `super+left` | previous tab | gnome-terminal |  |
| `super+right` | next tab | gnome-terminal |  |
| `super+1` | tab 1 | gnome-terminal, iterm2 | gnome-terminal ships these on alt+N, which would collide with tmux windows |
| `super+2` | tab 2 | gnome-terminal, iterm2 |  |
| `super+3` | tab 3 | gnome-terminal, iterm2 |  |
| `super+4` | tab 4 | gnome-terminal, iterm2 |  |
| `super+5` | tab 5 | gnome-terminal, iterm2 |  |
| `super+6` | tab 6 | gnome-terminal, iterm2 |  |
| `super+7` | tab 7 | gnome-terminal, iterm2 |  |
| `super+8` | tab 8 | gnome-terminal, iterm2 |  |
| `super+9` | tab 9 | gnome-terminal, iterm2 |  |
| `alt+0` | gnome-terminal tabs 10-20 unbound (no super key left for them) | gnome-terminal |  |
| `f10` | gnome-terminal menu accelerator off, so F10 reaches the program | gnome-terminal |  |
| `f11` | gnome-terminal full screen unbound, so F11 reaches vim (debugger step into) | gnome-terminal |  |

## tmux (alt = unprefixed, ctrl+x = prefix for rare operations)

Rendered to / applied by: .tmux/keys.conf, sourced by .tmux.conf

| key | action | apps | note |
| --- | --- | --- | --- |
| `ctrl+x` | tmux prefix | tmux |  |
| `alt+m` | toggle mouse reporting (on by default; shift+drag selects for the terminal) | tmux |  |
| `alt+\` | split right | tmux | 'M-\' is quoted in tmux: an unquoted backslash is eaten by the parser |
| `alt+-` | split below | tmux |  |
| `alt+z` | zoom pane | tmux |  |
| `alt+enter` | zoom pane | tmux |  |
| `alt+[` | swap pane up | tmux | ESC-[ is also the CSI introducer; works with extended-keys csi-u, may misfire elsewhere |
| `alt+]` | swap pane down | tmux |  |
| `alt+w` | kill pane | tmux |  |
| `\` | split right (prefix, old habit) | tmux |  |
| `-` | split below (prefix, old habit) | tmux |  |
| `"` | unbound (replaced by prefix -) | tmux |  |
| `%` | unbound (replaced by prefix \) | tmux |  |
| `alt+n` | new window | tmux |  |
| `alt+,` | previous window | tmux |  |
| `alt+.` | next window | tmux |  |
| `alt+1` | window 1 | tmux |  |
| `alt+2` | window 2 | tmux |  |
| `alt+3` | window 3 | tmux |  |
| `alt+4` | window 4 | tmux |  |
| `alt+5` | window 5 | tmux |  |
| `alt+6` | window 6 | tmux |  |
| `alt+7` | window 7 | tmux |  |
| `alt+8` | window 8 | tmux |  |
| `alt+9` | window 9 | tmux |  |
| `alt+h` | focus left | tmux |  |
| `alt+j` | focus down | tmux |  |
| `alt+k` | focus up | tmux |  |
| `alt+l` | focus right | tmux |  |
| `alt+left` | focus left | tmux |  |
| `alt+down` | focus down | tmux |  |
| `alt+up` | focus up | tmux |  |
| `alt+right` | focus right | tmux |  |
| `alt+tab` | next pane, never forwarded (the guaranteed way out) | tmux |  |
| `alt+shift+tab` | previous pane, never forwarded | tmux | rendered as both M-BTab and M-S-Tab, the two encodings terminals send |
| `alt+shift+h` | narrow | tmux |  |
| `alt+shift+j` | lengthen | tmux |  |
| `alt+shift+k` | shorten | tmux |  |
| `alt+shift+l` | widen | tmux |  |
| `alt+shift+left` | narrow | tmux |  |
| `alt+shift+down` | lengthen | tmux |  |
| `alt+shift+up` | shorten | tmux |  |
| `alt+shift+right` | widen | tmux |  |
| `pageup` | enter scrollback in a shell pane; passed through to pagers and vim | tmux | pagedown is left unbound so it always reaches the program |
| `ctrl+home` | scrollback top | tmux |  |
| `ctrl+end` | scrollback bottom | tmux |  |
| `ctrl+left` | previous word | tmux |  |
| `ctrl+right` | next word | tmux |  |
| `]` | paste tmux's own copy-mode buffer (prefix) | tmux |  |

## Shell line editing (bash readline, zsh zle)

Rendered to / applied by: .shell/.common.d/keys.sh

| key | action | apps | note |
| --- | --- | --- | --- |
| `home` | start of line | zsh, bash |  |
| `ctrl+a` | start of line | zsh, bash |  |
| `end` | end of line | zsh, bash |  |
| `ctrl+e` | end of line | zsh, bash |  |
| `delete` | delete char forward | zsh, bash |  |
| `ctrl+delete` | delete word forward | zsh, bash |  |
| `ctrl+left` | previous word start | zsh, bash |  |
| `ctrl+right` | next word start | zsh, bash | bash vi-fword, because readline's forward-word stops at the END of the word |

## vim

Rendered to / applied by: .vim/keys.vim, sourced by .vimrc

| key | action | apps | note |
| --- | --- | --- | --- |
| `enter` | clear search highlight | vim |  |
| `ctrl+up` | half page up | vim |  |
| `ctrl+down` | half page down | vim |  |
| `ctrl+a` | start of line | vim |  |
| `ctrl+e` | end of line | vim |  |
| `ctrl+t` | toggle NERDTree | vim |  |
| `alt+h` | split left (else tmux pane) | vim |  |
| `alt+j` | split down (else tmux pane) | vim |  |
| `alt+k` | split up (else tmux pane) | vim |  |
| `alt+l` | split right (else tmux pane) | vim |  |
| `alt+left` | split left (else tmux pane) | vim |  |
| `alt+down` | split down (else tmux pane) | vim |  |
| `alt+up` | split up (else tmux pane) | vim |  |
| `alt+right` | split right (else tmux pane) | vim |  |
| `alt+shift+h` | narrow (else tmux pane) | vim |  |
| `alt+shift+j` | lengthen (else tmux pane) | vim |  |
| `alt+shift+k` | shorten (else tmux pane) | vim |  |
| `alt+shift+l` | widen (else tmux pane) | vim |  |
| `alt+shift+left` | narrow (else tmux pane) | vim |  |
| `alt+shift+down` | lengthen (else tmux pane) | vim |  |
| `alt+shift+up` | shorten (else tmux pane) | vim |  |
| `alt+shift+right` | widen (else tmux pane) | vim |  |
| `f12` | go to definition (else tag jump) | vim |  |
| `ctrl+shift+f12` | go to declaration (else gD) | vim |  |
| `ctrl+f12` | go to implementation | vim |  |
| `shift+f12` | list references | vim |  |
| `alt+f12` | hover docs (else K) | vim |  |
| `f2` | rename symbol | vim |  |
| `f5` | start / continue | vim |  |
| `shift+f5` | stop and close debugger | vim |  |
| `ctrl+f5` | restart | vim |  |
| `f9` | toggle breakpoint | vim |  |
| `f10` | step over | vim |  |
| `f11` | step into | vim |  |
| `shift+f11` | step out | vim |  |
| `f8` | evaluate under cursor | vim |  |
