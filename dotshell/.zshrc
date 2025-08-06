source  /usr/local/share/zsh/site-functions

autoload -U +X compinit && compinit

plugins=()

setopt null_glob
for f in ${HOME}/.shell/common.d/*(.N); do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done
for f in ${HOME}/.shell/zsh.d/*(.N); do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done
unsetopt null_glob


#PS1='[\u@boromir \W$(__git_ps1 " (%s)")]\$ '
export PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
