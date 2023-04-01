#!/usr/bin/env bash

# Control Center settings.

# Show do not disturb option in control center.
defaults write com.apple.controlcenter \
  'NSStatusItem Visible DoNotDisturb' -bool true

# Dock settings.

# Set dock to autohide.
defaults write com.apple.dock autohide -bool true
# Set dock autohide delay time to 0 seconds.
defaults write com.apple.dock autohide-delay -float 0
# Do not show recent applications in the dock.
defaults write com.apple.dock show-recents -bool false

# File extension settings.

duti -s com.microsoft.VSCode bash all
duti -s com.microsoft.VSCode c all
duti -s com.microsoft.VSCode cfg all
duti -s com.microsoft.VSCode class all
duti -s com.microsoft.VSCode cpp all
duti -s com.microsoft.VSCode cs all
duti -s com.microsoft.VSCode css all
duti -s com.microsoft.VSCode csv all
duti -s com.microsoft.VSCode fish all
duti -s com.microsoft.VSCode go all
duti -s com.microsoft.VSCode h all
duti -s com.microsoft.VSCode ini all
duti -s com.microsoft.VSCode java all
duti -s com.microsoft.VSCode jl all
duti -s com.microsoft.VSCode js all
duti -s com.microsoft.VSCode json all
duti -s com.microsoft.VSCode log all
duti -s com.microsoft.VSCode lua all
duti -s com.microsoft.VSCode md all
duti -s com.microsoft.VSCode ps1 all
duti -s com.microsoft.VSCode py all
duti -s com.microsoft.VSCode rb all
duti -s com.microsoft.VSCode rs all
duti -s com.microsoft.VSCode sh all
duti -s com.microsoft.VSCode sql all
duti -s com.microsoft.VSCode swift all
duti -s com.microsoft.VSCode tf all
duti -s com.microsoft.VSCode tmp all
duti -s com.microsoft.VSCode toml all
duti -s com.microsoft.VSCode ts all
duti -s com.microsoft.VSCode tsv all
duti -s com.microsoft.VSCode txt all
duti -s com.microsoft.VSCode vue all
duti -s com.microsoft.VSCode xml all
duti -s com.microsoft.VSCode yaml all
duti -s org.mozilla.firefox html all
duti -s org.videolan.vlc avi all
duti -s org.videolan.vlc m4v all
duti -s org.videolan.vlc mov all
duti -s org.videolan.vlc mp4 all
duti -s org.videolan.vlc wmv all

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

# TextEdit settings.

# Save files to plain text by default.
defaults write com.apple.textedit RichText -bool false
