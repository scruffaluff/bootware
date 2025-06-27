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

# Change system keybindings.
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu []
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down '["<Shift><Control><Alt>Down"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left '["<Shift><Control><Alt>Left"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right '["<Shift><Control><Alt>Right"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up '["<Shift><Control><Alt>Up"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left '["<Alt><Control>Left"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right '["<Alt><Control>Right"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 '["<Alt><Control>1"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 '["<Alt><Control>2"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 '["<Alt><Control>3"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 '["<Alt><Control>4"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 '["<Alt><Control>5"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 '["<Alt><Control>6"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 '["<Alt><Control>7"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 '["<Alt><Control>8"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down '["<Alt><Control>K"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left '["<Alt><Control>J"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right '["<Alt><Control>Semicolon"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up '["<Alt><Control>L"]'
gsettings set org.gnome.shell.keybindings toggle-overview '["<Alt>Space"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys home '["<Alt><Super>Space"]'

# File extension settings.
xdg-mime default codium.desktop application/json
xdg-mime default codium.desktop application/x-sh
xdg-mime default codium.desktop application/xml
xdg-mime default codium.desktop text/css
xdg-mime default codium.desktop text/csv
xdg-mime default codium.desktop text/plain
xdg-mime default firefox.desktop image/avif
xdg-mime default firefox.desktop image/gif
xdg-mime default firefox.desktop image/webp
xdg-mime default libreoffice-calc.desktop application/vnd.ms-excel
xdg-mime default libreoffice-calc.desktop application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
xdg-mime default vlc.desktop audio/aac
xdg-mime default vlc.desktop audio/aiff
xdg-mime default vlc.desktop audio/flac
xdg-mime default vlc.desktop audio/mp4
xdg-mime default vlc.desktop audio/mpeg
xdg-mime default vlc.desktop audio/ogg
xdg-mime default vlc.desktop audio/wav
xdg-mime default vlc.desktop audio/webm
xdg-mime default vlc.desktop audio/x-ms-wma
xdg-mime default vlc.desktop video/mp4
xdg-mime default vlc.desktop video/mpeg
xdg-mime default vlc.desktop video/ogg
xdg-mime default vlc.desktop video/quicktime
xdg-mime default vlc.desktop video/webm
xdg-mime default vlc.desktop video/x-m4v
xdg-mime default vlc.desktop video/x-ms-wmv
xdg-mime default vlc.desktop video/x-msvideo
xdg-mime default vlc.desktop x-matroska
