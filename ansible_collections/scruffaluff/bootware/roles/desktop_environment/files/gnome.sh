#!/usr/bin/env sh
#
# Configure desktop settings for GNOME.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

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

# Replace Super with Super+Space as the application search keybinding.
gsettings set org.gnome.mutter overlay-key ''
gsettings set org.gnome.shell.keybindings toggle-overview '["<Super>Space"]'

# Change system keybindings.
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left '["<Alt><Control><Shift>Left"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right '["<Alt><Control><Shift>Right"]'
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized '["<Alt><Shift>M"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left '["<Alt><Control>Left"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right '["<Alt><Control>Right"]'

# File extension settings.
xdg-mime default code.desktop application/json
xdg-mime default code.desktop application/vnd.ms-excel
xdg-mime default code.desktop application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
xdg-mime default code.desktop application/x-sh
xdg-mime default code.desktop application/xml
xdg-mime default code.desktop text/css
xdg-mime default code.desktop text/csv
xdg-mime default code.desktop text/plain
xdg-mime default firefox.desktop application/pdf
xdg-mime default org.videolan.VLC.desktop video/mp4
xdg-mime default org.videolan.VLC.desktop video/x-msvideo
