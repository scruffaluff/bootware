#!/usr/bin/env sh
#
# Configure desktop settings for Fedora.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

# Use Adwaita (Light) color desktop theme.
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
# Use Adwaita (Light) color icon theme.
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
