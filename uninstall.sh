#!/bin/sh  
 
if [ ! -f ${HOME}/.dotfiles_installed ]; then
	echo "dotfiles not installed."
	exit 1
fi
cd $HOME
rm \
    .bash_profile \
    .bashrc \
    .zshrc \
    .zprofile \
    .zsh \
    .vim \
    .vimrc \
    .tmux.conf \
    .profile \
    .gitconfig \
    .shell \
    .dotfiles \
    .dotfiles_installed
cd $OLDPWD
