#!/usr/bin/env bash


# Use Pop (Light) color theme.
gsettings set org.gnome.desktop.interface gtk-theme Pop
# Tun Pop shell window gap size to zero.
gsettings set org.gnome.shell.extensions.pop-shell gap-outer uint32 0
gsettings set org.gnome.shell.extensions.pop-shell gap-inner uint32 0
# Turn on Pop shell window tiling.
gsettomgs set org.gnome.shell.extensions.pop-shell tile-by-default true
# Remove HiDPI notifications.
gsettings set com.system76.hidpi enable false
# Turn on HiDPI mode.
gsettings set com.system76.hidpi mode hidpi
