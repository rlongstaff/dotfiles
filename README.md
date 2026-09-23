# Dotfiles

This repo handles your homedir across various versions of Linux, MacOS, and WSL2.

# Features
- Manages all changes to your shell across all of your boxes with git.
- Minimal dependencies with safe fallbacks.
- Tmux and vim itegration: Tmux panes and vim buffers/windows are all handled seamlessly with
  keyboard and mouse navigation / resizing.
- vim IDE tools (NerdTree, LSPs, prediction, debugging).
- Keyboard / Color management system: Tired of a vim keybinding not working only to find you have
  the same keybind in your muxer? This handles the layering of terminal, muxer, shell, and
  application configuration. All keys, actions, and their respective layers are in a single
  location. It does the same for colors. Rendering the individual configs also updates cheatsheets
  and documentation.
- Unified copy/paste buffer for system, muxer, vim.
- A resilient ssh-agent wrapper that integrates with the system (MacOS: Keychain, Linuxs: GNOME
  Keychain, systemd) if available. If there is no managed ssh-agent, it will start one and share it
  across all terminals / sessions.
- A consistant appearance for bash and zsh. '$' for bash, '%' for zsh.
- Confirms presence of baseline QoL packages (tmux, vim, zsh, jq, yq, tldr, etc).
- Basic comfort directories: `$HOME`/{prj,bin,tmp}. `$HOME`/docs that will link to the OS-dependant
  version of "`$HOME`/Documents", "`$HOME`/My Documents", etc

# How do I install this?  

Install in your home directory:

Review the code before running !
- Option 1) `curl -Ls https://github.com/rlongstaff/dotfiles/install.sh | sh`
- Option 2) `curl -LOs https://github.com/rlongstaff/dotfiles/install.sh &&
    ./install.sh`
- Option 3) `git clone https://github.com/rlongstaff/dotfiles &&
    dotfiles/install.sh`

Install in a non-`$HOME` directory:
- `./install.sh /tmp/fakehome`

## .gitconfig Management
**Edit `~/.gitconfig.local`** with your name and email. `.gitconfig` (the tracked file) includes it,
so your identity never lives in the repo.

# Warning!  Installing this to `$HOME` will symlink files to the dotfiles install location.
Files linked this way will first be backed up to `$HOME`/.dotfiles.bak-`$TIMESTAMP`/.  These files
include, but are not limited to:

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
- .config/kitty, .config/alacritty, .config/labwc
- .Xresources, Library/LaunchAgents/us.dotfiles.keyboard.plist (macOS)

The full list is `LINKS` in `scripts/lib.sh`. Every link is absolute into the install location.
`scripts/check.sh` audits the links and lists real files in `$HOME` that should be managed here
instead.

Re-run any single step later with `scripts/install.d/<step>.sh`. Everything under `scripts/` sources
`scripts/lib.sh` and speaks only in `$SCRIPT_DIR` (the repo) and `$TARGET` (the home dir being set
up), so `./install.sh /tmp/fakehome` is a safe dry run: file changes land in the fake home and
live-session changes (gsettings, hidutil) are skipped.


# How do I get my preferences / tweaks working with this?
- If you installed via curl, there is no management. Tweak away.

- If you installed with git:
  - Create a new branch: `git checkout -b my_config`
  - Make your changes and commit: `git add . && git commit -m 'my changes'`
  - Periodically fetch the main branch and merge the updates: `git fetch && git merge main`
  - Fix any conflicts and commit

- Alternatively, you can install in a non-`$HOME` target. From there you can manually symlink what
  you want into your `$HOME`.


# Keyboard and Color Management

Bindings and colors are each defined once and rendered to every app's config:

- `keys.yaml` -> `scripts/keyboard/render.sh`->
  **[docs/keyboard-cheatsheet.md](docs/keyboard-cheatsheet.md)**
- `colors.yaml` -> `scripts/colors/render.sh` ->
  **[docs/colors-cheatsheet.md](docs/colors-cheatsheet.md)**

*needs `yq`, mikefarah v4

The keyboard standard (same finger positions on every machine and layer), vim's own defaults, and
the vim Go IDE (completion, go to definition, diagnostics, debugging via gopls, yegappan/lsp and
vimspector) are documented in **[docs/guide.md](docs/guide.md)**.

## What's with all the extra/comfort dirs?

Opinion: source and projects should not be muddled with ~/docs. ~/prj, ~/src -> ~/prj. Convention
that originated with Mac OS X to get a case-sensitive volume for code; The volume would be symlinked
to ~/prj.

~/src/github.com/: Put all your github repos in one place.

## This sucks, how do I get rid of it?
1. Run `./uninstall.sh`
2. Copy the .dotfiles.bak.`$TIMESTAMP` you want back to `$HOME`.

