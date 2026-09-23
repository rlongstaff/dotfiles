<!-- GENERATED from colors.yaml by scripts/colors/render.sh. Edit the yaml, not this file. -->

# Colour cheatsheet

Every colour in the dotfiles, generated from `colors.yaml` (repo root). Edit the yaml,
run `scripts/colors/render.sh`, commit both. Only the settings that have a value are
listed here; the yaml also lists every setting left at the app's default.

## Palette

The 16 terminal colours (kitty's defaults, pinned) and everything that uses each one.

| # | Name | Hex | Used by |
| - | ---- | --- | ------- |
| 0 | black | `#000000` | kitty: `background`, kitty: `selection_foreground`, kitty: `active_tab_foreground`, kitty: `mark1_foreground`, kitty: `mark2_foreground`, kitty: `mark3_foreground`, shell: `ls su` (fg), shell: `ls sg` (fg), shell: `ls tw` (fg), shell: `ls ow` (fg), vim: `LineNr` (bg) |
| 1 | red | `#cc0403` | shell: `ls su` (bg) |
| 2 | green | `#19cb00` | tmux: `@status-clock-fg`, shell: `ls ex` (fg), shell: `ls tw` (bg), shell: `prompt user` (fg), vim: `User3` (fg) |
| 3 | yellow | `#cecb00` | shell: `ls so` (fg), shell: `ls pi` (fg), shell: `ls cd` (bg), shell: `ls ow` (bg), shell: `prompt path` (fg), vim: `User4` (fg) |
| 4 | blue | `#0d73cc` | tmux: `mode-style` (bg), shell: `ls di` (fg), shell: `ls bd` (fg), shell: `ls cd` (fg), shell: `prompt host` (fg), vim: `LineNr` (fg), vim: `Visual` (bg) |
| 5 | magenta | `#cb1ed1` | shell: `ls ln` (fg), shell: `prompt git` (fg) |
| 6 | cyan | `#0dcdcd` | shell: `ls bd` (bg), shell: `ls sg` (bg), vim: `User2` (fg) |
| 7 | white | `#dddddd` | kitty: `foreground`, tmux: `status-style` (fg) |
| 8 | bright-black | `#767676` | shell: `prompt at` (fg), shell: `prompt colon` (fg), shell: `prompt time` (fg), vim: `User5` (fg) |
| 9 | bright-red | `#f2201f` | tmux: `@status-passthrough-bg`, vim: `User6` (fg) |
| 10 | bright-green | `#23fd00` |  |
| 11 | bright-yellow | `#fffd00` |  |
| 12 | bright-blue | `#1a8fff` |  |
| 13 | bright-magenta | `#fd28ff` |  |
| 14 | bright-cyan | `#14ffff` |  |
| 15 | bright-white | `#ffffff` | tmux: `mode-style` (fg), vim: `Visual` (fg), vim: `User1` (fg) |

## Terminal (kitty)

.config/kitty/colors.conf, included by kitty.conf (the palette renders there too)

**settings** (26 listed in the yaml)

| Setting | Value | What it colours | Why |
| ------- | ----- | ------- | --- |
| `foreground` | white | default text |  |
| `background` | black | default background |  |
| `selection_foreground` | black | text of a mouse selection |  |
| `selection_background` | #fffacd | background of a mouse selection |  |
| `cursor` | #cccccc | cursor block |  |
| `cursor_text_color` | #111111 | text under the cursor block |  |
| `url_color` | #0087bd | underline of a hovered URL |  |
| `visual_bell_color` | #606060 | flash for the visual bell | dimmer than kitty's default flash |
| `active_border_color` | #00ff00 | border of the focused kitty window |  |
| `inactive_border_color` | #cccccc | border of other kitty windows |  |
| `bell_border_color` | #ff5a00 | border of a window that rang the bell |  |
| `wayland_titlebar_color` | system | Wayland title bar | follow the desktop theme |
| `active_tab_foreground` | black | text of the current tab |  |
| `active_tab_background` | #eeeeee | current tab |  |
| `inactive_tab_foreground` | #444444 | text of other tabs |  |
| `inactive_tab_background` | #999999 | other tabs |  |
| `mark1_foreground` | black | text of mark 1 (marker highlighting) |  |
| `mark1_background` | #98d3cb | mark 1 |  |
| `mark2_foreground` | black | text of mark 2 |  |
| `mark2_background` | #f2dcd3 | mark 2 |  |
| `mark3_foreground` | black | text of mark 3 |  |
| `mark3_background` | #f274bc | mark 3 |  |

## tmux

.tmux/colors.conf, sourced by .tmux.conf

**settings** (31 listed in the yaml)

| Setting | Value | What it colours | Why |
| ------- | ----- | ------- | --- |
| `status-style` | fg white bg #003366 | status line |  |
| `@status-clock-fg` | green | clock in status-right | user option: status-right in .tmux.conf reads #{@status-clock-fg} |
| `@status-normal-bg` | #003366 | status line background | user option: matches status-style bg above; the alt+x binding in keys.yaml restores this explicitly rather than unsetting status-style, since unset would fall back to tmux's compiled-in default (green) rather than this value |
| `@status-passthrough-bg` | bright-red | status line while alt+x passthrough is active | user option: the alt+x binding in keys.yaml reads #{@status-passthrough-bg} |
| `mode-style` | fg bright-white bg blue | copy-mode selection | matches vim's Visual |

## Shells (bash and zsh)

.shell/.common.d/colors.sh; .bashrc builds PS1 from it, .zsh.d/prompt.zsh builds PROMPT

**prompt** (7 listed in the yaml)

| Setting | Value | What it colours | Why |
| ------- | ----- | ------- | --- |
| `user` | fg green | user name |  |
| `at` | fg bright-black | the @ between user and host |  |
| `host` | fg blue bold | host name (WSL on WSL) |  |
| `colon` | fg bright-black | the colon before the path |  |
| `path` | fg yellow | working directory |  |
| `git` | fg magenta | git branch and state |  |
| `time` | fg bright-black | right-side clock (zsh only: timeshow / timehide) |  |

**ls** (11 listed in the yaml)

| Setting | Value | What it colours | Why |
| ------- | ----- | ------- | --- |
| `di` | fg blue bold | directory |  |
| `ln` | fg magenta | symbolic link |  |
| `so` | fg yellow | socket |  |
| `pi` | fg yellow | named pipe |  |
| `ex` | fg green | executable |  |
| `bd` | fg blue bg cyan | block device |  |
| `cd` | fg blue bg yellow | character device |  |
| `su` | fg black bg red | setuid executable |  |
| `sg` | fg black bg cyan | setgid executable |  |
| `tw` | fg black bg green | sticky |  |
| `ow` | fg black bg yellow | other-writable directory |  |

## vim

.vim/colors.vim, sourced by .vimrc (after 'background' and syntax enable)

**groups** (175 listed in the yaml)

| Setting | Value | What it colours | Why |
| ------- | ----- | ------- | --- |
| `LineNr` | fg blue bg black | line number for ':number' and ':#' commands, and when 'number' or 'relativenumber' option... |  |
| `Visual` | fg bright-white bg blue | visual mode selection | matches tmux's mode-style |
| `User1` | fg bright-white bg 236 bold | statusline %1* | line, column and the %= fill: the main readout |
| `User2` | fg cyan bg 236 | statusline %2* | modified [+], /total, 0xchar: [+] has to stand out |
| `User3` | fg green bg 236 | statusline %3* | filetype |
| `User4` | fg yellow bg 236 bold | statusline %4* | full path; yellow like the prompt's path |
| `User5` | fg bright-black bg 236 | statusline %5* | line endings: rarely interesting, so dimmed |
| `User6` | fg bright-red bg 236 bold | statusline %6* | diagnostics: syntastic flag and LSP [E:n W:n] |
