# Dotfiles

This repo handles your homedir across various versions of Linux, MacOS, and WSL2.

# Features
- Manage all changes to your shell across all of your boxes with git
- Keep a consistant appearance for bash and zsh. The only difference will be the final prompt: '$' for bash '%' for zsh.
- A resilient ssh-agent wrapper that will share your agent across all terminals / sessions
- Install the bare minimum number of packages to make life liveable
- Creates basic comfort directories
- Adds ~/docs that will link to the OS-dependant version of "~/Documents", "~/My Documents", etc

# Warning!

When you install this, it will archive, then link the following files to the git repo. This makes it such that you can still edit your dotfiles as you normally would, but with more change control.

- .gitconfig
- .gitignore
- .tmux, .tmux.conf
- .vim
- .vimrc
- .bashrc
- .bash_profile
- .profile
- .zsh
- .zshrc
- .zprofile
- .config/kitty, .config/alacritty (directories); .config/labwc (Linux)
- .Xresources (Linux), Library/LaunchAgents/us.longstaff.keyboard.plist (macOS)

The list is `LINKS` in `scripts/lib.sh`. Every link is absolute into the repo, so editing
`~/.vimrc` edits the checkout and `git status` shows it. `scripts/check.sh` audits the links
and lists real files in `$HOME` that should be managed here instead.

# How do I install this?

1. Install git
2. Clone the repo. Put this where it will live permanently. Current convention is to locate it here `~/src/github.com/rlongstaff/dotfiles`
3. Run `scripts/pkgs/deb.sh` (required). This handles debian, ubuntu, WSL2. There is currently no script to install things via homebrew for MacOS
4. Run `scripts/pkgs/mac-tweaks.sh` if you want to stop some silly things for MacOS
5. Run `./install.sh` from the repo dir. This will backup any configs that it replaces to `~/.dotfiles.bak.{TIMESTAMP}`, then run each step in `scripts/install.d/` in order (symlinks, comfort dirs, keyboard standard, notes)
6. **!!!!!CHECK YOUR `.gitconfig`!!!!!** .gitconfig does not allow for shell expansion so you need to change your username and email
7. Exit your existing terminal and start a fresh one.

Re-run any single step later with `scripts/install.d/<step>.sh`. Everything under `scripts/`
sources `scripts/lib.sh` and speaks only in `$SCRIPT_DIR` (the repo) and `$TARGET` (the home
dir being set up), so `./install.sh /tmp/fakehome` is a safe dry run: file changes land in the
fake home and live-session changes (gsettings, hidutil) are skipped.

The keyboard standard (same finger positions on every machine and layer) is documented in
`docs/keyboard.md`. Every key binding for the compositor, terminal, tmux, the shells
and vim is defined once in `scripts/keyboard/keys.yaml`; `scripts/keyboard/render.sh` (needs
`yq`, mikefarah v4) regenerates each app's fragment and `docs/keyboard-cheatsheet.md`.

## This sucks, how do I get rid of it?
1. Run `./uninstall.sh`
2. Copy the .dotfiles.bak.{TIMESTAMP} you want back to $HOME.

## What's with all the extra/comfort dirs?

~/prj, ~/src->~/prj: Opinion: source and projects should not be muddled with ~/docs. Convention that originated with Mac OS X to get a case-sensitive volume for code; The volume would be symlinked to ~/prj.

~/src/github.com/: Put all your github repos in one place.

~/bin, ~/tmp: Go away.
