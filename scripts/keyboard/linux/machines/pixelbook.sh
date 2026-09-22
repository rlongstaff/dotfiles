# Pixelbook, running Linux.  Sourced by ../apply.sh (KBD_DIR set); see docs/keyboard.md.
#
# The Pixelbook bottom row is
#
#     [ctrl][alt][   space   ][alt][ctrl]
#
# There is no physical Super key, so `altwin:swap_lalt_lwin` has nothing to swap and
# the standard cannot be reached with stock xkb options alone.  The Search key sits in
# the Caps Lock position and already emits Super.
#
# Result:  Search(Caps position) -> Control   (the Control anchor, same as everywhere)
#          left of space         -> Super     (the Command anchor)
#          bottom-left corner    -> Alt       (the Alt anchor moves here)
#
# Bottom-left is Alt here and Control on the XPS.  That divergence is accepted: it is
# not one of the three anchors, and Control is still on Caps as it is on every other
# machine.
#
# LIMITATION: the LALT/LCTL rewrite below goes through xkbcomp, which is X11 only.  On a
# Wayland session it is skipped and only `ctrl:nocaps` lands, leaving Command on the
# bottom-left corner rather than next to space.  Fixing that under Wayland means
# installing a custom symbols file into /usr/share/X11/xkb/symbols as root, which is out
# of scope for a dotfiles checkout.  Run this Pixelbook on X11, or accept the gap.

XKB_OPTIONS="ctrl:nocaps"

xkb_extra() {
  which xkbcomp >/dev/null 2>&1 || return 0
  [ -n "${DISPLAY}" ] || return 0

  xkbcomp -I"${KBD_DIR}" -i "$(xinput_kbd_id)" - "${DISPLAY}" 2>/dev/null <<'EOF'
xkb_keymap {
  include "server:0"
  xkb_symbols {
    include "pc+us+inet(evdev)"
    // Caps position (Search) already handled by ctrl:nocaps.
    key <LALT> { [ Super_L ] };
    key <LCTL> { [ Alt_L   ] };
    modifier_map Mod4 { <LALT> };
    modifier_map Mod1 { <LCTL> };
  };
};
EOF
}

xinput_kbd_id() {
  which xinput >/dev/null 2>&1 || { echo 0; return; }
  xinput list --id-only 'AT Translated Set 2 keyboard' 2>/dev/null || echo 0
}
