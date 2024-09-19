#!/bin/bash

if [ ! -f ${HOME}/.homeconf_installed ]; then
	echo "homeconf not installed."
	exit 1
fi

LINKS="
    .bash
    .bash_profile
    .gitconfig
    .tmux.conf
    .vim
    .vimrc
    docs
    src
"

for i in ${LINKS}; do
    rm -f ${HOME}/${i}
done

rmdir ${HOME}/bin
rmdir ${HOME}/prj/github.com
rmdir ${HOME}/prj

rm ${HOME}/.homeconf_installed