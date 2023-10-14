#!/usr/bin/env bash

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge workspace-skip-tile ''

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-down '["<Control><Super>K"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-left '["<Control><Super>J"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-right '["<Control><Super>Semicolon"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-focus-up '["<Control><Super>L"]'

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-down '["<Control><Shift><Super>K"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-left '["<Control><Shift><Super>J"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-right '["<Control><Shift><Super>Semicolon"]'
gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-swap-up '["<Control><Shift><Super>L"]'

gsettings --schemadir "${HOME}/.local/share/gnome-shell/extensions/forge@jmmaranan.com/schemas" set org.gnome.shell.extensions.forge.keybindings window-toggle-float '["<Control><Shift><Super>F"]'
