# Dotfiles

Shell, tmux, vim and terminal configs for Linux, macOS and WSL2. bash is the baseline; zsh,
tmux and the vim IDE layer on top and fall back quietly when missing.

## Quick start

Review the script before running it.

curl, production cowboy mode
```sh
curl -fsSL https://raw.githubusercontent.com/rlongstaff/dotfiles/main/install.sh | sh
```

curl, review code first
```
curl -fsSLO https://raw.githubusercontent.com/rlongstaff/dotfiles/main/install.sh
less install.sh && sh install.sh
```

git
```
git clone https://github.com/rlongstaff/dotfiles && dotfiles/install.sh
```

Dry run against a throwaway home
```
./install.sh /tmp/fakehome
```

- Files already in `$HOME` are backed up to `~/.dotfiles.bak.<timestamp>` before linking.
- Put your name and email in `~/.gitconfig.local`; the tracked `.gitconfig` includes it.
- Undo with `./uninstall.sh`, then copy back the backup you want.

## What you get

**Bare minimum**

- Same shell config, prompt and aliases on every box (bash or zsh).
- vim core settings: indent, mouse, statusline, clipboard yank.
- Symlink installer with backups, an audit (`scripts/check.sh`) and an uninstaller.
- One shared ssh-agent per host, and OS-aware comfort dirs (`~/prj`, `~/bin`, `~/tmp`, `~/docs`).

**With enhancements**

- tmux autostart, including a nested, remote session per ssh login.
- vim IDE: file tree, LSP, completion, go-to, diagnostics and a debugger.
- Every key binding in `keys.yaml` and every color in `colors.yaml`, rendered to kitty,
  gnome-terminal, tmux, the shells and vim, with generated cheatsheets.
- Unified copy and paste across system, tmux and vim.

## Software and minimum versions

| Software | Minimum | For |
| -------- | ------- | --- |
| bash | 3.2 | required |
| vim | 8.x | required |
| git | any | required |
| curl, tar | any | curl install only |
| zsh | 5.x | optional |
| tmux | 3.2 | optional |
| vim | 9.0 | LSP |
| vim with `+python3` | 8.x | debugger |
| gopls, delve | any recent | Go LSP and debugger |
| yq (mikefarah) | v4 | re-rendering keys and colors |
| kitty, gnome-terminal, iTerm2 | any recent | terminal configs |

Packages, install commands and what happens without each item:
[guide, Requirements](docs/guide.md#requirements).

## Docs

- [Guide](docs/guide.md): requirements, keyboard standard, vim defaults, vim Go IDE.
- [Keyboard cheatsheet](docs/keyboard-cheatsheet.md): every binding, generated from `keys.yaml`.
- [Color cheatsheet](docs/colors-cheatsheet.md): every color, generated from `colors.yaml`.

## Notes

- Installing to `$HOME` symlinks files into the checkout, so edits to `~/.vimrc` and friends
  edit the repo. The full list is `LINKS` in `scripts/lib.sh`.
- Re-run one step with `scripts/install.d/<step>.sh`.
- Edit `keys.yaml` or `colors.yaml`, then run `scripts/keyboard/render.sh` or
  `scripts/colors/render.sh`. Never hand-edit a file that starts with GENERATED.

## Making it yours

- curl install: nothing tracks it, edit freely.
- git install: `git checkout -b my_config`, commit your changes, then periodically
  `git fetch && git merge main`.
- Or install to another directory and symlink only what you want.

## Comfort dirs

`~/prj` holds projects and `~/src` links to it, so repos live at `~/src/github.com/<user>/<repo>`.
`~/docs` links to the OS's Documents folder.
