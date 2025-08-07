#!/bin/sh

REPO=rlongstaff/dotfiles

GIT=github.com
BASE=${HOME}/prj/${GIT}/${REPO}

mkdir -p ${BASE}
git clone git@${GIT}:${REPO}.git ${BASE}
