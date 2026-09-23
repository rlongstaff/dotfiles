
# Colours: DOTFILES_C_ZSH_* from .common.d/colors.sh, GENERATED from colors.yaml.  Sourced
# here because oh-my-zsh loads this theme before .zshrc runs the .common.d loader.
[ -r "${HOME}/.shell/.common.d/colors.sh" ] && source "${HOME}/.shell/.common.d/colors.sh"

ZSH_THEME_GIT_PROMPT_PREFIX=" ${DOTFILES_C_ZSH_GIT}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${DOTFILES_C_ZSH_GIT_OFF} "
# ZSH_THEME_GIT_PROMPT_CLEAN="✔"
# ZSH_THEME_GIT_PROMPT_DIRTY="✗"

# shows * or a + for unstaged and staged changes, respectively
export GIT_PS1_SHOWSTASHSTATE=true
# shows $ if there are any stashes
export GIT_PS1_SHOWDIRTYSTATE=true
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
\$(git_prompt_info)\
${NEWLINE}\
╰ %# "
