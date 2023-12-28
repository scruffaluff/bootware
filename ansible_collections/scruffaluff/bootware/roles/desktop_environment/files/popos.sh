#!/usr/bin/env sh
#
# Configure desktop settings for PopOS.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

# Remove HiDPI notifications.
gsettings set com.system76.hidpi enable false
# Turn on HiDPI mode.
gsettings set com.system76.hidpi mode 'hidpi'
# Use Pop (Light) color theme.
gsettings set org.gnome.desktop.interface gtk-theme 'Pop'
