#!/bin/sh

set -e 

if [ -f ${HOME}/.homeconf_installed ]; then
	echo "homeconf already installed: ${HOME}/.homeconf_installed"
	exit 1
fi

DIR=$(dirname $0)

OLD_CFG=".bash_profile
.bsahrc
.profile
"

for i in ${OLD_CFG}; do
	mv ${HOME}/${i} ${HOME}/${i}.orig
done

CFG=".bash
.bash_profile
.gitconfig
.tmux.conf
.vim
.vimrc"

for i in ${CFG}; do
	ln -fs ${DIR}/${i} ${HOME}/${i}
done

if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
	WINUSER = $(perl -e 'use Env; ($_) = ${PATH} =~ /Users\/([^\/]+)\/AppData/; print;')
	ln -s /mnt/c/Users/${WINUSER}/Documents ${HOME}/docs
	mkdir -p ${HOME}/docs/notes
else
	ln -s ${HOME}/Documents ${HOME}/docs
	mkdir docs/notes
fi

mkdir ${HOME}/{bin,prj,.ssh,tmp}

ln -s ${HOME}/prj ${$HOME}src
mkdir -p ${HOME}/src/github.com

chmod 700 ${HOME}/.ssh

touch ${HOME}/.homeconf_installed
