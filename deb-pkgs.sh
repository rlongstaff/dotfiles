#!/bin/bash

PKGS=(
     bash-completion
     docker.io
     wamerican
)

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install ${PKGS[@]}
