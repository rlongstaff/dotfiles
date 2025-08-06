#!/bin/sh

alias python=python3

export VIRTUAL_ENV_DISABLE_PROMPT=1

if [ -f ${HOME}/prj/virtualenv/main/bin/activate ]; then
    source ${HOME}/prj/virtualenv/main/bin/activate
elif [ -f ${HOME}/prj/virpy/main/bin/activate ]; then
    source ${HOME}/prj/virpy/main/bin/activate
fi
