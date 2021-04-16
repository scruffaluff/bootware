#!/usr/bin/env bash

# Use Adwaita (Light) color desktop theme.
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
# Use Adwaita (Light) color icon theme.
gsettings set org.gnome.desktop.interface icon-theme "Adwaita"
# Use natural scroll orientation for mouse. Natural scroll appears to be
# backwards on Fedora.
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false
