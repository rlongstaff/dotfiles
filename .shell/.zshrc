source ${HOME}/.shell/.dotfilesrc

# Before the loader: completion.sh and gcloud.sh call compdef / complete.
autoload -U +X compinit && compinit

# Case- and hyphen-insensitive: _ and - are interchangeable.
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|=*' 'l:|=* r:|=*'

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# zsh saves no history unless HISTFILE is set.
HISTFILE=${HOME}/.zsh_history
HISTSIZE=50000
SAVEHIST=10000

# Ditch the extra carriage return when using history substitutions
unsetopt HIST_VERIFY

unsetopt AUTO_CD

setopt null_glob
for f in ${HOME}/.shell/.common.d/*.(inc|sh); do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done
for f in ${HOME}/.shell/.zsh.d/*.(inc|sh|zsh); do
    [ -r "$f" ] && [ -f "$f" ] && source "$f"
done
unsetopt null_glob

# After the loader, so PATH is complete (.common.d/completion.sh).
dotfiles_completion

# Last: the shell tmux returns to is fully loaded (.common.d/tmux.sh).
dotfiles_tmux_autostart
