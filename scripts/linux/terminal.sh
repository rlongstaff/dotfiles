#!/bin/sh
#
# Terminal-emulator half of the keyboard standard on Linux.  See ../README.md.
#
# The terminal emulator owns Cmd/Super, because Cmd/Super has no byte encoding and so
# can never reach tmux or vim.  iTerm2 already binds Cmd-C/V/T/W and Cmd-1..9 natively,
# so macOS needs nothing here -- this file exists to move Linux terminals onto Super so
# the two match.
#
# Copy and paste are tier-1: ONE gesture, single modifier plus key, identical on
# GNOME/Wayland, fluxbox/X11 and macOS, all writing the same CLIPBOARD selection.
# Terminals covered, in scope order: gnome-terminal and iTerm2 (required), alacritty and
# kitty (nice to have), xterm (optional, and the fluxbox/X11 guarantee).
#
# Firefox and other GTK/desktop applications are deliberately untouched -- they keep
# Ctrl-C/V.  Nothing here rebinds a global modifier; Super is *added* in the terminals,
# not substituted for Control anywhere.
#
#   Super-C / Super-V   copy / paste
#   Super-T / Super-W   new tab / close tab
#   Super-N             new window
#   Super-1 .. Super-9  tab N
#   Super-Left/Right    prev / next tab
#   Super-Tab           switch application  (the OS, not the terminal -- matches Cmd-Tab)
#
# Alt is left completely alone here: it belongs to tmux and vim.
#
# Idempotent.  Self-guarding: each block no-ops when its terminal is not installed.

set -e

# --------------------------------------------------------------------------------------
# GNOME Shell first: it holds Super-1..9 for the dash, which would swallow the tab keys.
# --------------------------------------------------------------------------------------
if which gsettings >/dev/null 2>&1 \
   && gsettings list-schemas 2>/dev/null | grep -q '^org\.gnome\.shell\.keybindings$'; then
  i=1
  while [ $i -le 9 ]; do
    gsettings set org.gnome.shell.keybindings "switch-to-application-${i}" "[]"
    i=$((i + 1))
  done

  # GNOME Shell also holds Super-A (the app grid) and Super-N (focus the last
  # notification).  Both are grabbed by the compositor, so they never reach the focused
  # terminal at all -- select-all and new-window would look bound and do nothing.
  gsettings set org.gnome.shell.keybindings toggle-application-view "[]"
  gsettings set org.gnome.shell.keybindings focus-active-notification "[]"

  # Super-V has shipped as toggle-message-tray in some GNOME versions.  It is the paste
  # key, so it is released unconditionally rather than checked: a grab here means paste
  # is dead in every terminal on the machine and nothing indicates why.
  gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>m']"

  echo "keyboard: released Super-1..9, Super-A, Super-N, Super-V from GNOME Shell"
fi

# --------------------------------------------------------------------------------------
# Alt-Tab belongs to the terminal, not the window manager.
#
# GNOME ships switch-applications bound to BOTH <Super>Tab and <Alt>Tab, so the same
# gesture is on two modifiers and the Alt one shadows tmux's pane cycling before the
# terminal ever sees the keystroke.  Pinning it to Super-Tab alone does two things at
# once: it matches macOS, where Cmd-Tab is the application switcher and Option-Tab is
# free, and it frees Alt-Tab to reach tmux -- which is the modifier rule this whole
# standard runs on (Super = OS and terminal emulator, Alt = inside the terminal).
#
# Same treatment for the backward pair, or Alt-Shift-Tab would still be caught here while
# Alt-Tab passed through, which is worse than either consistent outcome.
# --------------------------------------------------------------------------------------
if which gsettings >/dev/null 2>&1 \
   && gsettings list-schemas 2>/dev/null | grep -q '^org\.gnome\.desktop\.wm\.keybindings$'; then
  gsettings set org.gnome.desktop.wm.keybindings switch-applications \
    "['<Super>Tab']"
  gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward \
    "['<Shift><Super>Tab']"
  echo "keyboard: Alt-Tab released to tmux; app switching is Super-Tab"
fi

# --------------------------------------------------------------------------------------
# gnome-terminal.  Relocatable schema, so the path suffix is mandatory.
# --------------------------------------------------------------------------------------
if which gnome-terminal >/dev/null 2>&1 && which gsettings >/dev/null 2>&1; then
  GT="org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/"

  gsettings set "$GT" copy       "'<Super>c'"
  gsettings set "$GT" paste      "'<Super>v'"
  gsettings set "$GT" select-all "'<Super>a'"
  gsettings set "$GT" find       "'<Super>f'"
  gsettings set "$GT" new-tab    "'<Super>t'"
  gsettings set "$GT" close-tab  "'<Super>w'"
  gsettings set "$GT" new-window "'<Super>n'"
  gsettings set "$GT" prev-tab   "'<Super>Left'"
  gsettings set "$GT" next-tab   "'<Super>Right'"

  # switch-to-tab-N ships bound to <Alt>N, which would collide head-on with the tmux
  # window keys.  Moving them to Super is what frees Alt for tmux.
  i=1
  while [ $i -le 9 ]; do
    gsettings set "$GT" "switch-to-tab-${i}" "'<Super>${i}'"
    i=$((i + 1))
  done
  # Beyond 9 there is no Super key to use; unbind rather than leave them on Alt.
  i=10
  while [ $i -le 20 ]; do
    gsettings set "$GT" "switch-to-tab-${i}" "'disabled'" 2>/dev/null || true
    i=$((i + 1))
  done

  gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false
  echo "keyboard: gnome-terminal moved to Super; Alt released to tmux"
fi

# --------------------------------------------------------------------------------------
# alacritty.  TOML since 0.13; the older YAML format is not written.  Own file, included
# from alacritty.toml, so a hand-written config is never clobbered.
# --------------------------------------------------------------------------------------
if which alacritty >/dev/null 2>&1; then
  AL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"
  mkdir -p "${AL_DIR}"
  cat > "${AL_DIR}/keyboard.toml" <<'EOF'
# Generated by dotfiles keyboard/linux/terminal.sh -- edits here are overwritten.

[[keyboard.bindings]]
key = "C"
mods = "Super"
action = "Copy"

[[keyboard.bindings]]
key = "V"
mods = "Super"
action = "Paste"

[[keyboard.bindings]]
key = "N"
mods = "Super"
action = "CreateNewWindow"
EOF

  if [ ! -f "${AL_DIR}/alacritty.toml" ]; then
    printf 'import = ["%s/keyboard.toml"]\n' "${AL_DIR}" > "${AL_DIR}/alacritty.toml"
  elif ! grep -q 'keyboard\.toml' "${AL_DIR}/alacritty.toml"; then
    printf '\nimport = ["%s/keyboard.toml"]\n' "${AL_DIR}" >> "${AL_DIR}/alacritty.toml"
  fi
  echo "keyboard: alacritty moved to Super"
fi

# --------------------------------------------------------------------------------------
# kitty.  'include' is relative to kitty.conf's directory.
# --------------------------------------------------------------------------------------
if which kitty >/dev/null 2>&1; then
  KI_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
  mkdir -p "${KI_DIR}"
  cat > "${KI_DIR}/keyboard.conf" <<'EOF'
# Generated by dotfiles keyboard/linux/terminal.sh -- edits here are overwritten.
map super+c copy_to_clipboard
map super+v paste_from_clipboard
map super+n new_os_window
map super+t new_tab
map super+w close_tab
EOF

  if [ ! -f "${KI_DIR}/kitty.conf" ]; then
    printf 'include keyboard.conf\n' > "${KI_DIR}/kitty.conf"
  elif ! grep -q 'keyboard\.conf' "${KI_DIR}/kitty.conf"; then
    printf '\ninclude keyboard.conf\n' >> "${KI_DIR}/kitty.conf"
  fi
  echo "keyboard: kitty moved to Super"
fi

# --------------------------------------------------------------------------------------
# xterm.  No config file of its own: shortcuts are X resources, and the modifier is
# spelled the Xt way ('Super', which is mod4 -- the same key GTK calls <Super>).
#
# CLIPBOARD is named explicitly in both directions.  xterm's defaults deal in PRIMARY,
# which is the middle-click selection and a *different* buffer from the one GTK apps and
# Firefox use; naming CLIPBOARD is what puts every platform on one clipboard.
#
# metaSendsEscape goes in the same block: xterm's default is to set the eighth bit for
# Alt rather than prefixing ESC, and tmux and vim read the ESC prefix.  Without it the
# whole Alt layer is dead in xterm, which looks like a tmux problem and is not.
#
# Written to ~/.Xresources and merged now, so it takes effect without a re-login.  This
# is the fluxbox/X11 path; xterm is the optional tier, but it is also the terminal a
# minimal X session is guaranteed to have.
# --------------------------------------------------------------------------------------
if which xterm >/dev/null 2>&1; then
  XRES="${HOME}/.Xresources"
  BEGIN='! >>> dotfiles keyboard >>>'
  END='! <<< dotfiles keyboard <<<'

  # Drop any previous block first, so re-running does not stack duplicates.  sed rather
  # than grep -v because the block spans lines that are not individually marked.
  if [ -f "${XRES}" ]; then
    sed -i "\\|^${BEGIN}\$|,\\|^${END}\$|d" "${XRES}"
  fi

  cat >> "${XRES}" <<EOF
${BEGIN}
XTerm*metaSendsEscape: true
XTerm*vt100.translations: #override \\
    Super <Key>c: copy-selection(CLIPBOARD) \\n\\
    Super <Key>v: insert-selection(CLIPBOARD)
${END}
EOF

  if which xrdb >/dev/null 2>&1 && [ -n "${DISPLAY}" ]; then
    xrdb -merge "${XRES}" && echo "keyboard: xterm moved to Super (merged into the live server)"
  else
    echo "keyboard: xterm moved to Super (~/.Xresources; takes effect next X session)"
  fi
fi

# --------------------------------------------------------------------------------------
# fluxbox.  It grabs Mod4 combinations only if ~/.fluxbox/keys says so, which the stock
# file does not -- but a hand-edited one might, and a window-manager grab beats the
# terminal every time.  Warn rather than rewrite: keys(5) is the user's file.
# --------------------------------------------------------------------------------------
if [ -f "${HOME}/.fluxbox/keys" ] \
   && grep -qiE '^[[:space:]]*mod4[[:space:]]+[cv][[:space:]]' "${HOME}/.fluxbox/keys"; then
  echo "keyboard: WARNING ~/.fluxbox/keys grabs Mod4-C or Mod4-V; copy/paste will not"
  echo "keyboard:         reach the terminal until those lines are removed."
fi

# No tab bindings for alacritty (it has no tabs) or xterm (it has none either); both are
# reachable through tmux, which is the point of putting the frequent operations there.
