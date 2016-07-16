#!/bin/sh

CFG=".bash
.bash_profile
.bashrc
.gitconfig
.tmux.conf
.vim
.vimrc"

for i in $CFG; do
	ln -fs prj/robconf/$i $HOME/$i
done
