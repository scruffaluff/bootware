#!/usr/bin/env sh
#
# Configure desktop settings for GNOME.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

font_size="${BOOTWARE_FONT_SIZE:-12}"

# Show weekday in top bar date.
gsettings set org.gnome.desktop.interface clock-show-weekday true

# Prevent switch to activities view when mouse is in top level desktop corner.
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Show battery percentage in activity bar.
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Do not show notifications in the lock screen.
gsettings set org.gnome.desktop.notifications show-in-lock-screen false

# Set keyboard typing speeds.
gsettings set org.gnome.desktop.peripherals.keyboard delay 256
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 16

# Use natural scroll orientation for mouse.
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true
# Set mouse speed.
gsettings set org.gnome.desktop.peripherals.mouse speed 0.8

# Use natural scroll orientation for touchpad.
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
# Set touchpad speed.
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.5

# Disable file history.
gsettings set org.gnome.desktop.privacy remember-recent-files false

# Maximize application windows when double clicking the title bar.
gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar \
  'toggle-maximize'

# Disable error bells.
gsettings set org.gnome.desktop.wm.preferences audible-bell true
gsettings set org.gnome.desktop.wm.preferences visual-bell false

# Add maximize and minimize buttons to application window title bars.
gsettings set org.gnome.desktop.wm.preferences button-layout \
  'appmenu:minimize,maximize,close'

# Enable dynamic workspaces.
gsettings set org.gnome.mutter dynamic-workspaces true
# Enable dyanimc workspaces for all monitors.
gsettings set org.gnome.mutter workspaces-only-on-primary false

# Show hidden files in file applications.
gsettings set org.gnome.nautilus.preferences show-hidden-files true
gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden true
gsettings set org.gtk.Settings.FileChooser show-hidden true

# Turn off automatic brightness
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false

# Use home directory for file selection dialogs.
gsettings set org.gtk.gtk4.Settings.FileChooser startup-mode 'cwd'
gsettings set org.gtk.Settings.FileChooser startup-mode 'cwd'

# Change system fonts.
gsettings set org.gnome.desktop.interface document-font-name "Fira Sans ${font_size}"
gsettings set org.gnome.desktop.interface font-name "Fira Sans ${font_size}"
gsettings set org.gnome.desktop.interface monospace-font-name "Fira Code ${font_size}"

# Disable system keybinding conflicts.
gsettings set org.freedesktop.ibus.general.hotkey trigger []
gsettings set org.freedesktop.ibus.general.hotkey triggers []
gsettings set org.freedesktop.ibus.panel.emoji hotkey []
gsettings set org.freedesktop.ibus.panel.emoji unicode-hotkey []
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu []
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 []
gsettings set org.gnome.desktop.wm.keybindings switch-input-source []
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward []
gsettings set org.gnome.mutter.wayland.keybindings restore-shortcuts []
gsettings set org.gnome.settings-daemon.plugins.media-keys home []
gsettings set org.gnome.shell.keybindings open-new-window-application-1 []
gsettings set org.gnome.shell.keybindings open-new-window-application-2 []
gsettings set org.gnome.shell.keybindings open-new-window-application-3 []
gsettings set org.gnome.shell.keybindings open-new-window-application-4 []
gsettings set org.gnome.shell.keybindings open-new-window-application-5 []
gsettings set org.gnome.shell.keybindings open-new-window-application-6 []
gsettings set org.gnome.shell.keybindings open-new-window-application-7 []
gsettings set org.gnome.shell.keybindings open-new-window-application-8 []
gsettings set org.gnome.shell.keybindings open-new-window-application-9 []
gsettings set org.gnome.shell.keybindings switch-to-application-1 []
gsettings set org.gnome.shell.keybindings switch-to-application-2 []
gsettings set org.gnome.shell.keybindings switch-to-application-3 []
gsettings set org.gnome.shell.keybindings switch-to-application-4 []
gsettings set org.gnome.shell.keybindings switch-to-application-5 []
gsettings set org.gnome.shell.keybindings switch-to-application-6 []
gsettings set org.gnome.shell.keybindings switch-to-application-7 []
gsettings set org.gnome.shell.keybindings switch-to-application-8 []
gsettings set org.gnome.shell.keybindings switch-to-application-9 []
gsettings set org.gnome.shell.keybindings toggle-message-tray []
gsettings set org.gnome.shell.keybindings toggle-quick-settings []
gsettings set org.gnome.desktop.wm.keybindings minimize []

# Change system keybindings.
gsettings set org.gnome.desktop.wm.keybindings maximize '["<Super>Up"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down '["<Control><Shift><Super>Down"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left '["<Control><Shift><Super>Left"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right '["<Control><Shift><Super>Right"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up '["<Control><Shift><Super>Up"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down '["<Control><Super>Down"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left '["<Control><Super>Left"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right '["<Control><Super>Right"]'
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up '["<Control><Super>Up"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 '["<Control><Super>1"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 '["<Control><Super>2"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 '["<Control><Super>3"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 '["<Control><Super>4"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 '["<Control><Super>5"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 '["<Control><Super>6"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 '["<Control><Super>7"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 '["<Control><Super>8"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down '["<Control><Super>K"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left '["<Control><Super>J"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right '["<Control><Super>Semicolon"]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up '["<Control><Super>L"]'
gsettings set org.gnome.desktop.wm.keybindings unmaximize '["<Super>Down"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys home '["<Alt><Super>Space"]'
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver '["<Super>Escape"]'
gsettings set org.gnome.shell.keybindings toggle-overview '["<Alt>Space","<Super>Space"]'

# Change system theme.
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
gsettings set org.gnome.desktop.wm.preferences theme 'Adwaita'

# File extension settings.
xdg-mime default zed.desktop application/json
xdg-mime default zed.desktop application/x-sh
xdg-mime default zed.desktop application/xml
xdg-mime default zed.desktop text/css
xdg-mime default zed.desktop text/csv
xdg-mime default zed.desktop text/plain
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
