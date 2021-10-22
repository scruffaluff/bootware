#!/usr/bin/env bash

# Control Center settings.

# Show do not disturb option in control center.
defaults write com.apple.controlcenter "NSStatusItem Visible DoNotDisturb" -bool true

# Dock settings.

# Set dock to autohide.
defaults write com.apple.dock autohide -bool true
# Set dock autohide delay time to 0 seconds.
defaults write com.apple.dock autohide-delay -float 0
# Do not show recent applications in the dock.
defaults write com.apple.dock show-recents -bool false

# File extension settings.

duti -s com.microsoft.VSCode md all
duti -s com.microsoft.VSCode js all
duti -s com.microsoft.VSCode ts all
duti -s com.microsoft.VSCode py all

# Finder settings.

# Show hidden files in Finder.
defaults write com.apple.finder AppleShowAllFiles -bool true
# Disable file extension change warning.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Show items in Finder via icon view.
defaults write com.apple.Finder FXPreferredViewStyle icnv
# Sort items in Finder by name.
defaults write com.apple.Finder FXPreferredGroupBy Name
# Show path bar in Finder folder window.
defaults write com.apple.finder ShowPathbar -bool true
# Do not show removable media on the desktop.
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
# Show status bar in Finder folder window.
defaults write com.apple.finder ShowStatusBar -bool true
# Show file extensions in Finder.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Do not autosave files to iCloud.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Keyboard settings.

# Increase cursor movement to max speed.
defaults write NSGlobalDomain KeyRepeat 1
# Minimize delay for cursor movement to smallest time.
defaults write NSGlobalDomain InitialKeyRepeat 10

# TextEdit settings.

# Save files to plain text by default.
defaults write com.apple.textedit RichText -bool false
