source  /usr/local/share/zsh/site-functions

autoload -U +X compinit && compinit

for f in ${HOME}/.shell/common.d/*; do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done
for f in ${HOME}/.shell/zsh.d/*; do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done

#PS1='[\u@boromir \W$(__git_ps1 " (%s)")]\$ '
