
# Line-editing keys, in every encoding a terminal might send.  See
# ~/.dotfiles/keyboard/README.md.
#
#   Home / End                beginning / end of line
#   Delete                    delete the character under the cursor
#   Ctrl-Left / Ctrl-Right    back / forward one word
#   Ctrl-Delete               delete the word ahead
#
# Each means the same thing in bash, zsh, tmux copy-mode and vim.  tmux and vim already
# agree; the shells did not, which is what this file fixes.
#
# The problem is that a terminal has four different ways to say "Home", and which one it
# picks depends on the emulator AND on whether the cursor keys are in application mode:
#
#     ESC [ H     "CSI"  -- kitty, alacritty, and VTE in normal mode
#     ESC O H     "SS3"  -- VTE/gnome-terminal and xterm in application mode
#     ESC [ 1 ~   "vt"   -- what tmux and screen re-emit to the programs inside them
#     ESC [ 7 ~   rxvt
#
# Ctrl-Left/Ctrl-Right have the same problem in four forms of their own (`ESC [ 1 ; 5 D`,
# `ESC O 5 D`, `ESC [ 5 D`, `ESC O d`), and Delete is `ESC [ 3 ~` essentially everywhere.
#
# bash's stock readline binds the first three already.  zsh binds exactly ONE: whichever
# `khome`/`kend` names for the current TERM.  So zsh Home/End works in gnome-terminal and
# silently does nothing in kitty or alacritty, which send the CSI form that TERM=xterm-256color
# does not name.  Binding all four in both shells removes the dependency on terminfo and on
# application mode entirely -- the key means the same thing regardless of how it arrived.
#
# Must load after oh-my-zsh, which it does: .zshrc sources .common.d/ further down.

case $- in
  *i*) ;;
  *) return 0 2>/dev/null || true ;;
esac

if [ -n "$ZSH_VERSION" ]; then
  # -M on both keymaps: emacs is the oh-my-zsh default, but a vi-mode shell must not lose
  # these, and binding the current keymap only would depend on which one happens to be up.
  for _kmap in emacs viins; do
    bindkey -M "$_kmap" '^[[H'  beginning-of-line
    bindkey -M "$_kmap" '^[OH'  beginning-of-line
    bindkey -M "$_kmap" '^[[1~' beginning-of-line
    bindkey -M "$_kmap" '^[[7~' beginning-of-line
    bindkey -M "$_kmap" '^[[F'  end-of-line
    bindkey -M "$_kmap" '^[OF'  end-of-line
    bindkey -M "$_kmap" '^[[4~' end-of-line
    bindkey -M "$_kmap" '^[[8~' end-of-line

    # Delete.  oh-my-zsh already binds these two; restated so the set does not depend on
    # a plugin, and so a bare zsh with no framework behaves identically.
    bindkey -M "$_kmap" '^[[3~'   delete-char
    bindkey -M "$_kmap" '^[[3;5~' kill-word

    # Word motion.  oh-my-zsh binds only the xterm form; the other three are the gap.
    bindkey -M "$_kmap" '^[[1;5D' backward-word
    bindkey -M "$_kmap" '^[O5D'   backward-word
    bindkey -M "$_kmap" '^[[5D'   backward-word
    bindkey -M "$_kmap" '^[Od'    backward-word
    bindkey -M "$_kmap" '^[[1;5C' forward-word
    bindkey -M "$_kmap" '^[O5C'   forward-word
    bindkey -M "$_kmap" '^[[5C'   forward-word
    bindkey -M "$_kmap" '^[Oc'    forward-word
  done
  unset _kmap

  # Where a word ends, so Ctrl-Left/Right travels the same distance as it does in bash.
  # zsh's own default is '*?_-.[]~=/&;!#$%^(){}<>', which swallows a whole path in one
  # press -- bash stops at every non-alphanumeric.  oh-my-zsh happens to empty this
  # already, but the shells must agree without depending on a framework being installed.
  WORDCHARS=''
fi

if [ -n "$BASH_VERSION" ]; then
  # Mostly already readline's defaults; restated so the set does not depend on the readline
  # version, on /etc/inputrc, or on a ~/.inputrc that redefines them.  The rxvt pair is the
  # one genuinely missing from stock readline.
  bind '"\e[H":  beginning-of-line'
  bind '"\eOH":  beginning-of-line'
  bind '"\e[1~": beginning-of-line'
  bind '"\e[7~": beginning-of-line'
  bind '"\e[F":  end-of-line'
  bind '"\eOF":  end-of-line'
  bind '"\e[4~": end-of-line'
  bind '"\e[8~": end-of-line'

  # Delete.  Ctrl-Delete is the one readline does not ship.
  bind '"\e[3~":   delete-char'
  bind '"\e[3;5~": kill-word'

  # Word motion.  readline already has the xterm and rxvt-bracket forms; the SS3 pair is
  # what is missing.
  #
  # vi-fword, not forward-word: readline's forward-word stops at the END of the current
  # word, while zsh, vim's `w` and tmux's next-word all stop at the START of the next one.
  # bash was the only layer of the four that disagreed, so bash is the one that moves.
  # vi-bword matches backward-word here -- both go to the start of the previous word --
  # but it is used for symmetry, so the pair cannot drift apart on a future readline.
  bind '"\e[1;5D": vi-bword'
  bind '"\eO5D":   vi-bword'
  bind '"\e[5D":   vi-bword'
  bind '"\eOd":    vi-bword'
  bind '"\e[1;5C": vi-fword'
  bind '"\eO5C":   vi-fword'
  bind '"\e[5C":   vi-fword'
  bind '"\eOc":    vi-fword'
fi
