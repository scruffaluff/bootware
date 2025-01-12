#!/usr/bin/env sh
#
# Configure Forge window manager settings.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge focus-border-toggle false
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge move-pointer-focus-enabled true
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge showtab-decoration-enabled false
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge window-gap-size 2
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge workspace-skip-tile ''

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-down '["<Alt><Shift>K"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-left '["<Alt><Shift>J"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-right '["<Alt><Shift>Semicolon"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-up '["<Alt><Shift>L"]'

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-down '["<Alt><Shift>Down"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-left '["<Alt><Shift>Left"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-right '["<Alt><Shift>Right"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-up '["<Alt><Shift>Up"]'

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings con-tabbed-layout-toggle '["<Alt><Shift>M"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-toggle-float '["<Alt><Shift>F"]'
