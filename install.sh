#!/bin/sh

set -e
set -o pipefail
#set -x

REPO="dotfiles"
REPO_URL="https://github.com/rlongstaff/${REPO}"

help() {
  echo "Usage: \$0 [target_dir]"
  echo
  echo "Install in your home directory:"
  echo "  Option 1) curl -Ls ${REPO_URL}/install.sh | sh"
  echo "  Option 2) curl -LOs ${REPO_URL}/install.sh \\"
  echo "            # Review the code! \\"
  echo "            ./install.sh"
  echo "  Option 3) git clone ${REPO_URL} \\ "
  echo "            $REPO/install.sh"
  echo
  echo "Install in a different directory"
  echo "            install.sh ~/src/dotfiles"
  
  exit 0
}

SCRIPT_DIR=$(realpath $(dirname $0))
INSTALL_CANARY=".${REPO}_installed"
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
BACKUP_DIR="${SCRIPT_DIR}/${REPO}.bak.${TIMESTAMP}"

# Files to (re)place with symlinks in $TARGET
FILEZ="
.gitconfig
.gitignore
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

if [ ! -t 0 ]; then
  # stdin is not a terminal, likely piped
  echo "STOP PIPING RANDOM TEXT FROM THE INTERNET INTO YOUR SHELL!"
fi


TARGET=$1
if [ -z "${TARGET}" ]; then
	TARGET=$HOME
elif [ ${TARGET} = "help" -o ${TARGET} = "--help" ]; then
  help
else
	TARGET=$(realpath ${TARGET})
fi

if [ -z "${REPO}" ]; then
  echo "No REPO set!"
  exit 1
fi

if [ -f ${TARGET}/${INSTALL_CANARY} ]; then
	echo "${REPO} already installed: ${TARGET}/${INSTALL_CANARY}"
	exit 1
fi

LOCAL_REPO="$TARGET/.$REPO"

# set up our backup directory / backup existing repo
if [ -e ${LOCAL_REPO} ]; then
  mv ${LOCAL_REPO} ${BACKUP_DIR}
else
  mkdir -p ${BACKUP_DIR}
fi

# Do we have our friemds?
if [ -f ${SCRIPT_DIR}/uninstall.sh ]; then
  # Yup, use this as home base
  ln -sf ${SCRIPT_DIR} ${LOCAL_REPO}
else
  # Nope, grab them
  TMPDIR=$(mktemp -d)
  curl -Ls "${REPO_URL}/archive/refs/heads/main.tar.gz" \
    | tar xz -C ${TMPDIR}

  mv ${TMPDIR}/${REPO}-main ${LOCAL_REPO}
  rmdir ${TMPDIR}
fi

# Symlink all of the files into target
cd $TARGET
for i in ${FILEZ}; do
	b=$(basename ${i})
	if [ -e ${TARGET}/${b} ]; then
		mv ${TARGET}/${b} ${BACKUP_DIR}/ 2>/dev/null
	fi
	ln -sf .${REPO}/${i} ${b}
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

# Basic ssh skel
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
	ln -s prj ${TARGET}/src
fi

# golang likes to have things this way
if [ ! -d ${TARGET}/src/github.com ]; then
	mkdir -p ${TARGET}/src/github.com
fi

# ditch the backup is it's empty
if [ -z "$(ls -A ${BACKUP_DIR})" ]; then
  rmdir ${BACKUP_DIR}
fi

touch ${TARGET}/${INSTALL_CANARY}

echo "The following is to pin ohmyzsh to a check-valve repo"
echo "This allows for examination of deltas without blindy"
echo "  installing things into your shell"
echo
echo "Install ohmyzsh:"
echo '	sh -c "$(curl -fsSL https://raw.githubusercontent.com/rlongstaff/ohmyzsh/master/tools/install.sh)"'
echo
echo "CHECK YOUR .gitconfig [USER] SECTION!!!!"
