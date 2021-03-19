#!/usr/bin/env bash


# Use Adwaita (Light) color theme.
gsettings set org.gnome.desktop.interface gtk-theme Adwaita
# Use natural scroll orientation for mouse. Natural scroll appears to be
# backwards on Fedora.
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false

# Enable Pop shell extension.
gnome-extensions enable pop-shell@system76.com
# Tun Pop shell window gap size to zero.
gsettings set org.gnome.shell.extensions.pop-shell gap-outer 0
gsettings set org.gnome.shell.extensions.pop-shell gap-inner 0
# Turn on Pop shell window tiling.
gsettings set org.gnome.shell.extensions.pop-shell tile-by-default true
