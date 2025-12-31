#!/bin/sh

# set -e
# set -x

TARGET=$1
if [ -z "${TARGET}" ]; then
	TARGET=$HOME
else
	TARGET=$(realpath ${TARGET})
fi

INSTALLED=${TARGET}/.dotfiles_installed

if [ -f ${INSTALLED} ]; then
	echo "dotfiles already installed: ${INSTALLED}"
	exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=${TARGET}/.dotfiles.bak.${TIMESTAMP}
mkdir -p ${BACKUP_DIR}

DIR=$(realpath $(dirname $0))

if [ ! ${DIR} -ef ${TARGET}/.dotfiles ]; then
	if [ -e ${TARGET}/.dotfiles ]; then
		mv ${TARGET}/.dotfiles ${BACKUP_DIR}/
	fi
	ln -sf ${DIR} ${TARGET}/.dotfiles
fi


FILEZ="
.gitconfig
.tmux.conf
.vim
.vimrc
.shell
.shell/.bashrc
.shell/.bash_profile
.shell/.profile
.shell/.zsh
.shell/.zshrc
.shell/.zprofile
"

cd $TARGET
for i in ${FILEZ}; do
	b=$(basename ${i})
	if [ -e ${TARGET}/${b} ]; then
		mv ${TARGET}/${b} ${BACKUP_DIR}/ 2>/dev/null
	fi
	ln -sf .dotfiles/${i} ${b}
done

# Get our ~/docs folders uniform across systems
if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
	# Windows Subsystem for Linux (WSL)
	WINUSER=$(perl -e 'use Env; ($_) = ${PATH} =~ /Users\/([^\/]+)\/AppData/; print;')
	ln -s /mnt/c/Users/${WINUSER}/Documents ${TARGET}/docs
	ln -s /mnt/c/Users/${WINUSER}/Downloads ${TARGET}/downloads
	ln -s /mnt/c/Users/${WINUSER} ${TARGET}/win
elif [ -d ${TARGET}/Documents ]; then
	# Regular Linux or macOS
	ln -sf Documents ${TARGET}/docs
fi
if [ ! -d ${TARGET}/docs/notes ]; then
	mkdir -p ${TARGET}/docs/notes
fi

cd $OLDPWD

COMFORT_DIRS="
	bin
	tmp
	prj
"

for i in ${COMFORT_DIRS}; do
	if [ ! -d ${TARGET}/${i} ]; then
		mkdir -p ${TARGET}/${i}
	fi
done

if [ ! -d ${TARGET}/.ssh ]; then
	mkdir -p ${TARGET}/.ssh
	chmod 700 ${TARGET}/.ssh
fi
if [ ! -f ${TARGET}/.ssh/authorized_keys ]; then
	touch ${TARGET}/.ssh/authorized_keys
	chmod 600 ${TARGET}/.ssh/authorized_keys
fi

# Set ~/src to ~/prj; ignore if ~/src already exists
if [ ! -e ${TARGET}/src ]; then
	ln -s ${TARGET}/prj ${TARGET}/src
fi

# golang likes to have things this way
if [ ! -d ${TARGET}/src/github.com ]; then
	mkdir -p ${TARGET}/src/github.com
fi

touch ${INSTALLED}

echo "The following is to pin ohmyzsh to a check-valve repo"
echo "This allows for examination of deltas without blindy"
echo "  installing things into your shell"
echo
echo "Install ohmyzsh:"
echo '	sh -c "$(curl -fsSL https://raw.githubusercontent.com/rlongstaff/ohmyzsh/master/tools/install.sh)"'
echo
echo "CHECK YOUR .gitconfig [USER] SECTION!!!!"