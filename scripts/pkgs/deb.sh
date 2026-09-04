#!/bin/bash

PKGS=(
     bash-completion
     jq
     wamerican
     tmux
     vim
     zsh
     # Clipboard tools, so a vim yank (`yy`) reaches the system clipboard -- vim is built
     # -clipboard here, so it pipes to one of these.  Mouse copy does not need them: that
     # is Shift-drag plus Cmd-C, handled entirely by the terminal emulator.  One per
     # session type; installing both is harmless, since .vimrc picks one at runtime.
     wl-clipboard
     tealdeer
     xclip
)

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install ${PKGS[@]}
