#!/bin/sh

DIR=$(dirname $0)

CFG=".bash
.bash_profile
.bashrc
.gitconfig
.tmux.conf
.vim
.vimrc"

for i in $CFG; do
	ln -fs ${DIR}/$i $HOME/$i
done
