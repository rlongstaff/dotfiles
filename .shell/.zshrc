autoload -U +X compinit && compinit

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_CUSTOM=${HOME}/.zsh

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="rlongstaff"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

plugins=(
    # 1password: this plugin adds 1Password functionality to oh-my-zsh.
    # aws
    # azure
    docker
    gcloud
    # gitfast
    # git-commit # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git-commit
    golang # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/golang
    helm
    kubectl
    macos # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/macos
    minikube
    # thefuck
    themes
    tmux
)

source $ZSH/oh-my-zsh.sh

# User configuration

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# Replacing much of this with ohmyzsh
# source  /usr/local/share/zsh/site-functions

setopt null_glob
for f in ${HOME}/.shell/.common.d/*.(inc|sh); do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done
for f in ${HOME}/.shell/.zsh.d/*.(inc|sh|zsh); do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done
unsetopt null_glob


