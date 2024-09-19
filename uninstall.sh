#!/bin/bash

LINKS=(
    .bash
    .bash_profile
    .gitconfig
    .tmux.conf
    .vim
    .vimrc
    docs
)

rm -f ${HOME}/${LINKS[@]}