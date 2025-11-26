#!/bin/bash

PKGS=(
     bash-completion
     jq
     docker.io
     wamerican
     tmux
     zsh
)

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install ${PKGS[@]}
