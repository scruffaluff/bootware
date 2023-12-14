#!/usr/bin/env sh

# Show weekday in top bar date.
gsettings set org.gnome.desktop.interface clock-show-weekday true

# Prevent switch to activities view when mouse is in top level desktop corner.
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Show battery percentage in activity bar.
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Do not show notifications in the lock screen.
gsettings set org.gnome.desktop.notifications show-in-lock-screen false

# Use natural scroll orientation for mouse.
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true

# Use natural scroll orientation for touchpad.
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true

# Maximize application windows when double clicking the title bar.
gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar \
  'toggle-maximize'

# Add maximize and minimize buttons to application window title bars.
gsettings set org.gnome.desktop.wm.preferences button-layout \
  'appmenu:minimize,maximize,close'

# Use dynamic workspaces.
gsettings set org.gnome.mutter dynamic-workspaces true

# Show hidden files in Nautilus Files application.
gsettings set org.gnome.nautilus.preferences show-hidden-files true
gsettings set org.gtk.Settings.FileChooser show-hidden true

# Turn off automatic brightness
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false

# Change system keybindings.
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left '["<Alt><Control><Shift>Left"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right '["<Alt><Control><Shift>Right"]'
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized '["<Alt><Shift>M"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left '["<Alt><Control>Left"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right '["<Alt><Control>Right"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys search '["<Super>Space"]'
