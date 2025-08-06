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
.zshrc
.zprofile
"

for i in ${OLD_CFG}; do
	if [ -f ${HOME}/${i} ];then
		mv ${HOME}/${i} ${HOME}/${i}.orig
	fi
done

CFG=".bashrc
.bash_profile
.zshrc
.zprofile
.gitconfig
.tmux.conf
.vim
.vimrc"

for i in ${CFG}; do
	ln -fs ${DIR}/${i} ${HOME}/${i}
done

ln -fs ${DIR}/dotshell ${HOME}/.shell

if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
	WINUSER=$(perl -e 'use Env; ($_) = ${PATH} =~ /Users\/([^\/]+)\/AppData/; print;')
	ln -s /mnt/c/Users/${WINUSER}/Documents ${HOME}/docs
	mkdir -p ${HOME}/docs/notes
	ln -s /mnt/c/Users/${WINUSER}/Downloads ${HOME}/downloads
	ln -s /mnt/c/Users/${WINUSER} ${HOME}/win

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

read -p "Do you want to install oh-my-zsh? (y/n) " answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
