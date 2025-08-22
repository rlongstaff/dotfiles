
ZSH_THEME_GIT_PROMPT_PREFIX=" %F{magenta}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f "
# ZSH_THEME_GIT_PROMPT_CLEAN="✔"
# ZSH_THEME_GIT_PROMPT_DIRTY="✗"

# shows * or a + for unstaged and staged changes, respectively
export GIT_PS1_SHOWSTASHSTATE=true
# shows $ if there are any stashes
export GIT_PS1_SHOWDIRTYSTATE=true
# shows % if there are any untracked files
export GIT_PS1_SHOWUNTRACKEDFILES=true

export LSCOLORS=Exfxcxdxbxegedabagacad

NEWLINE=$'\n'

alias timeshow="RPROMPT='%F{8}%D/%*%f'"
alias timehide="unset RPROMPT"

PROMPT="\
╭─%F{green}%n%f\
%F{8}@%f\
%B%F{blue}%m%f%b\
%F{8}:%f\
%F{yellow}%3~%f\
\$(git_prompt_info)\
${NEWLINE}\
╰ %# "
