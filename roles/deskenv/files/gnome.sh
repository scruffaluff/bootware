#!/usr/bin/env bash


# Change background picture.
gsettings set org.gnome.desktop.background picture-uri "file:///home/$1/Pictures/background/$2"
# Show weekday in top bar date.
gsettings set org.gnome.desktop.interface clock-show-weekday true
# Show battery percentage in activity bar.
gsettings set org.gnome.desktop.interface show-battery-percentage true
# Use natural scroll orientation for mouse.
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true
# Use natural scroll orientation for touchpad.
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
# Change lock screen picture.
gsettings set org.gnome.desktop.screensaver picture-uri "file:///home/$1/Pictures/background/$2"
# Maximize application windows when double clicking the title bar.
gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar "toggle-maximize"
# Add maximize and minimize buttons to application window title bars.
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"

# Use dynamic workspaces.
gsettings set org.gnome.mutter dynamic-workspaces true

# Do not show notifications in the lock screen.
org.gnome.desktop.notifications show-in-lock-screen false

# Show hidden files in Nautilus Files application.
gsettings set org.gtk.Settings.FileChooser show-hidden true
gsettings set org.gnome.nautilus.preferences show-hidden-files true

# Turn off automatic brightness
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false
