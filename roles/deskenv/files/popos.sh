#!/usr/bin/env bash


# Use Pop (Light) color theme.
gsettings set org.gnome.desktop.interface gtk-theme "Pop"

# Remove HiDPI notifications.
gsettings set com.system76.hidpi enable false
# Turn on HiDPI mode.
gsettings set com.system76.hidpi mode "hidpi"
