source  /usr/local/share/zsh/site-functions

autoload -U +X compinit && compinit

source ${HOME}/dotshell/common.d/*
source ${HOME}/dotshell/zsh.d/*

#PS1='[\u@boromir \W$(__git_ps1 " (%s)")]\$ '
