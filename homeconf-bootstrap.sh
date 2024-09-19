#!/bin/sh

GIT=github.com
REPO=rlongstaff/robconf
BASE=${HOME}/prj/${GIT}/${REPO}

mkdir -p ${BASE}
git clone git@${GIT}:${REPO}.git ${BASE}
