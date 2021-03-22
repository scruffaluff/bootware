#!/usr/bin/env bash
#
# GSettings errors are ignored since Pop Shell settings are not available for
# all installations within GSettings.

# Tun Pop shell window gap size to zero.
gsettings set org.gnome.shell.extensions.pop-shell gap-outer 0 || true
gsettings set org.gnome.shell.extensions.pop-shell gap-inner 0 || true
# Turn on Pop shell window tiling.
gsettings set org.gnome.shell.extensions.pop-shell tile-by-default true || true
