#!/usr/bin/env sh

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge workspace-skip-tile ''

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-down '["<Alt><Shift>K"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-left '["<Alt><Shift>J"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-right '["<Alt><Shift>Semicolon"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-up '["<Alt><Shift>L"]'

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-down '["<Alt><Control><Shift>K"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-left '["<Alt><Control><Shift>J"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-right '["<Alt><Control><Shift>Semicolon"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-up '["<Alt><Control><Shift>L"]'

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-toggle-float '["<Alt><Control><Shift>F"]'
