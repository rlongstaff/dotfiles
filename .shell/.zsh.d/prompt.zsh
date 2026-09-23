# Two-line prompt.  Must match the bash PS1 in .shell/.bashrc; the only intended
# difference is the final % vs $.  The git segment is __git_ps1 from the vendored
# .common.d/git-prompt.sh, same as bash.  Its argument is a printf format, hence the
# colours' % doubled to %%.  Colours are DOTFILES_C_ZSH_* from
# .common.d/colors.sh (GENERATED from colors.yaml), already loaded by the .common.d loader.

setopt PROMPT_SUBST

# shows * or a + for unstaged and staged changes, respectively
export GIT_PS1_SHOWDIRTYSTATE=true
# shows $ if there are any stashes
export GIT_PS1_SHOWSTASHSTATE=true
# shows % if there are any untracked files
export GIT_PS1_SHOWUNTRACKEDFILES=true

NEWLINE=$'\n'

alias timeshow="RPROMPT='${DOTFILES_C_ZSH_TIME}%D/%*${DOTFILES_C_ZSH_TIME_OFF}'"
alias timehide="unset RPROMPT"

PROMPT="\
╭─${DOTFILES_C_ZSH_USER}%n${DOTFILES_C_ZSH_USER_OFF}\
${DOTFILES_C_ZSH_AT}@${DOTFILES_C_ZSH_AT_OFF}\
${DOTFILES_C_ZSH_HOST}%m${DOTFILES_C_ZSH_HOST_OFF}\
${DOTFILES_C_ZSH_COLON}:${DOTFILES_C_ZSH_COLON_OFF}\
${DOTFILES_C_ZSH_PATH}%3~${DOTFILES_C_ZSH_PATH_OFF}\
\$(__git_ps1 ' ${DOTFILES_C_ZSH_GIT//\%/%%}%s${DOTFILES_C_ZSH_GIT_OFF//\%/%%} ')\
${NEWLINE}\
╰ %# "
