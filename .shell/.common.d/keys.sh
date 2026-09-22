# GENERATED from scripts/keyboard/keys.yaml by render.sh. Edit the yaml, not this file.
#
# Line-editing keys for both shells, in every byte form a terminal might send (the form
# depends on the emulator and on application-cursor mode).  Binding all of them removes
# the dependency on terminfo, on /etc/inputrc, and on any zsh framework.
# Rationale: scripts/keyboard/README.md, "Navigation keys".

case $- in
  *i*) ;;
  *) return 0 2>/dev/null || true ;;
esac

if [ -n "$ZSH_VERSION" ]; then
  # Both keymaps, so a vi-mode zsh keeps these too.
  for _kmap in emacs viins; do

    # -- line ---------------------------------------------------------------------
    bindkey -M "$_kmap" '^[[H'     beginning-of-line
    bindkey -M "$_kmap" '^[OH'     beginning-of-line
    bindkey -M "$_kmap" '^[[1~'    beginning-of-line
    bindkey -M "$_kmap" '^[[7~'    beginning-of-line
    bindkey -M "$_kmap" '^[[F'     end-of-line
    bindkey -M "$_kmap" '^[OF'     end-of-line
    bindkey -M "$_kmap" '^[[4~'    end-of-line
    bindkey -M "$_kmap" '^[[8~'    end-of-line
    bindkey -M "$_kmap" '^[[3~'    delete-char
    bindkey -M "$_kmap" '^[[3;5~'  kill-word

    # -- words --------------------------------------------------------------------
    bindkey -M "$_kmap" '^[[1;5D'  backward-word
    bindkey -M "$_kmap" '^[O5D'    backward-word
    bindkey -M "$_kmap" '^[[5D'    backward-word
    bindkey -M "$_kmap" '^[Od'     backward-word
    # bash vi-fword, because readline's forward-word stops at the END of the word
    bindkey -M "$_kmap" '^[[1;5C'  forward-word
    bindkey -M "$_kmap" '^[O5C'    forward-word
    bindkey -M "$_kmap" '^[[5C'    forward-word
    bindkey -M "$_kmap" '^[Oc'     forward-word
  done
  unset _kmap

  # A word ends at every non-alphanumeric, as in bash; zsh's default swallows whole paths.
  WORDCHARS=''
fi

if [ -n "$BASH_VERSION" ]; then

  # -- line -----------------------------------------------------------------------
  bind '"\e[H": beginning-of-line'
  bind '"\eOH": beginning-of-line'
  bind '"\e[1~": beginning-of-line'
  bind '"\e[7~": beginning-of-line'
  bind '"\e[F": end-of-line'
  bind '"\eOF": end-of-line'
  bind '"\e[4~": end-of-line'
  bind '"\e[8~": end-of-line'
  bind '"\e[3~": delete-char'
  bind '"\e[3;5~": kill-word'

  # -- words ----------------------------------------------------------------------
  bind '"\e[1;5D": vi-bword'
  bind '"\eO5D": vi-bword'
  bind '"\e[5D": vi-bword'
  bind '"\eOd": vi-bword'
  # bash vi-fword, because readline's forward-word stops at the END of the word
  bind '"\e[1;5C": vi-fword'
  bind '"\eO5C": vi-fword'
  bind '"\e[5C": vi-fword'
  bind '"\eOc": vi-fword'
fi
