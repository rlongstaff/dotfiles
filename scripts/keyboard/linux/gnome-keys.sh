# GENERATED from scripts/keyboard/keys.yaml by render.sh. Edit the yaml, not this file.
# Sourced by linux/terminal.sh, which defines gset() and gates it on a live GNOME
# session.  gset SCHEMA KEY VALUE.  Order matters: outermost layer released first.

# gnome-terminal's keybinding schema is relocatable, so the path is part of its name.
GT="org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/"

# -- GNOME Shell: windows ---------------------------------------------------------
gset org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
gset org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"

# -- GNOME Shell: gnome releases --------------------------------------------------
gset org.gnome.shell.keybindings switch-to-application-1 "[]"
gset org.gnome.shell.keybindings switch-to-application-2 "[]"
gset org.gnome.shell.keybindings switch-to-application-3 "[]"
gset org.gnome.shell.keybindings switch-to-application-4 "[]"
gset org.gnome.shell.keybindings switch-to-application-5 "[]"
gset org.gnome.shell.keybindings switch-to-application-6 "[]"
gset org.gnome.shell.keybindings switch-to-application-7 "[]"
gset org.gnome.shell.keybindings switch-to-application-8 "[]"
gset org.gnome.shell.keybindings switch-to-application-9 "[]"
gset org.gnome.shell.keybindings toggle-application-view "[]"
gset org.gnome.shell.keybindings focus-active-notification "[]"
gset org.gnome.shell.keybindings toggle-message-tray "['<Super>m']"

# -- gnome-terminal: clipboard ----------------------------------------------------
gset "$GT" copy "'<Super>c'"
gset "$GT" paste "'<Super>v'"
gset "$GT" select-all "'<Super>a'"
gset "$GT" find "'<Super>f'"

# -- gnome-terminal: tabs ---------------------------------------------------------
gset "$GT" new-tab "'<Super>t'"
gset "$GT" close-tab "'<Super>w'"
gset "$GT" new-window "'<Super>n'"
gset "$GT" prev-tab "'<Super>Left'"
gset "$GT" next-tab "'<Super>Right'"
gset "$GT" switch-to-tab-1 "'<Super>1'"
gset "$GT" switch-to-tab-2 "'<Super>2'"
gset "$GT" switch-to-tab-3 "'<Super>3'"
gset "$GT" switch-to-tab-4 "'<Super>4'"
gset "$GT" switch-to-tab-5 "'<Super>5'"
gset "$GT" switch-to-tab-6 "'<Super>6'"
gset "$GT" switch-to-tab-7 "'<Super>7'"
gset "$GT" switch-to-tab-8 "'<Super>8'"
gset "$GT" switch-to-tab-9 "'<Super>9'"
gset "$GT" switch-to-tab-10 "'disabled'"
gset "$GT" switch-to-tab-11 "'disabled'"
gset "$GT" switch-to-tab-12 "'disabled'"
gset "$GT" switch-to-tab-13 "'disabled'"
gset "$GT" switch-to-tab-14 "'disabled'"
gset "$GT" switch-to-tab-15 "'disabled'"
gset "$GT" switch-to-tab-16 "'disabled'"
gset "$GT" switch-to-tab-17 "'disabled'"
gset "$GT" switch-to-tab-18 "'disabled'"
gset "$GT" switch-to-tab-19 "'disabled'"
gset "$GT" switch-to-tab-20 "'disabled'"
gset org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false
