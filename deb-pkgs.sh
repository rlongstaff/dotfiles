#!/bin/bash

PKGS=(
     bash-completion
     jq
     wamerican
     tmux
     vim
     zsh
     # Clipboard fallback for .keyboard/'s copy support.  Not the primary mechanism --
     # tmux and vim both copy via OSC 52, which needs nothing installed and is the only
     # thing that works over ssh.  These cover a local terminal that refuses OSC 52.
     # One per session type; installing both is harmless, since each is chosen at runtime.
     wl-clipboard
     tealdeer
     xclip
)

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install ${PKGS[@]}
