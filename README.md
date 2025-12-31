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
- .tmux.conf
- .vim
- .vimrc
- .bashrc
- .bash_profile
- .profile
- .zsh
- .zshrc
- .zprofile

# How do I install this?

1. Install git
2. Clone the repo. Put this where it will live permanently. Current convention is to locate it here `~/src/github.com/rlongstaff/dotfiles`
3. Run `deb-pkgs.sh` (required). This handles debian, ubuntu, WSL2. The is currently no script to install things via homebrew for MacOS
4. Run `mac-tweaks` if you want to stop some silly things for MacOS
5. Run `./install.sh` from the repo dir. This will backup any configs that it replaces to `~/.dotfiles.backup.{TIMESTAMP}`
6. **!!!!!CHECK YOUR `.gitconfig`!!!!!** .gitconfig does not allow for shell expansion so you need to change your username and email
7. Exit your existing terminal and start a fresh one.

## This sucks, how do I get rid of it?
1. Run `./uninstall.sh`
2. Copy the .dotfiles.backup.{TIMESTAMP} you want back to $HOME.

## What's with all the extra/comfort dirs?

~/prj, ~/src->~/prj: Opinion: source and projects should not be muddled with ~/docs. Convention that originated with Mac OS X to get a case-sensitive volume for code; The volume would be symlinked to ~/prj.

~/src/github.com/: Put all your github repos in one place.

~/bin, ~/tmp: Go away.
