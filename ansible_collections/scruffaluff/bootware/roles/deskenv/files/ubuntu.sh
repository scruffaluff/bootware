#!/usr/bin/env bash

# Use Yaru-lightcolor theme.
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-light'
# Hide dock.
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
# Do not show home folder icon on desktop.
gsettings set org.gnome.shell.extensions.desktop-icons show-home false
# Do not show trash icon on desktop.
gsettings set org.gnome.shell.extensions.desktop-icons show-trash false
