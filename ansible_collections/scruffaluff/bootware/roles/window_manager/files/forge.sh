#!/usr/bin/env sh
#
# Configure Forge window manager settings.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge focus-border-color 'rgba(253, 246, 227, 1)'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge focus-border-size 2
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge focus-border-toggle false
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge focus-on-hover-enabled true
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge move-pointer-focus-enabled true
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge showtab-decoration-enabled false
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge split-border-color 'rgba(253, 246, 227, 1)'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge window-gap-size 2
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge workspace-skip-tile ''

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings con-tabbed-layout-toggle '["<Shift><Super>M"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-toggle-float '["<Shift><Super>F"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings focus-border-toggle '["<Control><Super>B"]'

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-down '["<Shift><Super>K"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-left '["<Shift><Super>J"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-right '["<Shift><Super>Semicolon"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-up '["<Shift><Super>L"]'

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-down '["<Shift><Super>Down"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-left '["<Shift><Super>Left"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-right '["<Shift><Super>Right"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-up '["<Shift><Super>Up"]'
