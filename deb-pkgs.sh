#!/bin/bash

PKGS=(
     bash-completion
     jq
     wamerican
     tmux
     vim
     zsh
)

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install ${PKGS[@]}
