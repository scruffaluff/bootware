#!/usr/bin/env bash


# Use Adwaita (Light) color theme.
gsettings set org.gnome.desktop.interface gtk-theme Adwaita
# Use natural scroll orientation for mouse. Natural scroll appears to be
# backwards on Fedora.
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
