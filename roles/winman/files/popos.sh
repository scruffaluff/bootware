#!/usr/bin/env bash


# Tun Pop shell window gap size to zero.
gsettings set org.gnome.shell.extensions.pop-shell gap-outer 0
gsettings set org.gnome.shell.extensions.pop-shell gap-inner 0
# Turn on Pop shell window tiling.
gsettings set org.gnome.shell.extensions.pop-shell tile-by-default true
