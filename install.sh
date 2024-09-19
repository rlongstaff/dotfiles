#!/bin/sh

set -e
set -x

if [ -f ${HOME}/.homeconf_installed ]; then
	echo "homeconf already installed: ${HOME}/.homeconf_installed"
	exit 1
fi

DIR=$(dirname $0)

OLD_CFG=".bash_profile
.bashrc
.profile
"

for i in ${OLD_CFG}; do
	if [ -f ${HOME}/${i} ];then
		mv ${HOME}/${i} ${HOME}/${i}.orig
	fi
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
	WINUSER=$(perl -e 'use Env; ($_) = ${PATH} =~ /Users\/([^\/]+)\/AppData/; print;')
	ln -s /mnt/c/Users/${WINUSER}/Documents ${HOME}/docs
	mkdir -p ${HOME}/docs/notes
elif [ -d ${HOME}/Documents ]; then
	ln -s ${HOME}/Documents ${HOME}/docs
	mkdir docs/notes
else
	mkdir -p docs/notes
fi

COMFORT_DIRS="
	bin
	tmp
	prj
	.ssh
"
for i in ${COMFORT_DIRS}; do
	mkdir -p ${HOME}/${i}
done

ln -s ${HOME}/prj ${HOME}/src
mkdir -p ${HOME}/src/github.com

chmod 700 ${HOME}/.ssh

touch ${HOME}/.homeconf_installed
