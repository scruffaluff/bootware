#!/usr/bin/env sh
#
# Configure desktop settings for MacOS. To get nested settings in XML format use
# command `defaults export <domain> -`.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

# Control Center settings.

# Show do not disturb option in control center.
defaults write com.apple.controlcenter \
  'NSStatusItem Visible DoNotDisturb' -bool true

# Desktop settings.

# Prevent Stage Manager from hiding windows after a left click on desktop.
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
defaults write com.apple.WindowManager GloballyEnabled -bool false
# Prevent accent character popup when holding down a key.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Disble Apple intelligence report.
defaults write com.apple.AppleIntelligenceReport reportDuration -float 0
# Disable Apple handling passwordless autofill.
defaults write com.apple.Safari AutoFillPasswords -bool false
# Delete verification codes after use.
defaults write com.apple.onetimepasscodes DeleteVerificationCodes -bool true

# Dock and menu bar settings.

# Set dock to autohide.
defaults write com.apple.dock autohide -bool true
# Set dock autohide delay time to 0 seconds.
defaults write com.apple.dock autohide-delay -float 0
# Use simplier minimized animation for hiding applications.
defaults write com.apple.dock mineffect scale
# Minimize multiple windows of an applications to one dock icon.
defaults write com.apple.dock minimize-to-application -bool true
# Do not show recent applications in the dock.
defaults write com.apple.dock show-recents -bool false
# Disable arranging spaces based on recent use for Amethyst.
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock workspaces-auto-swoosh -bool false
# Remove keyboard settings from menu bar.
defaults write com.apple.TextInputMenu visible -bool false

# File extension settings.

duti -s com.microsoft.VSCodium bash all
duti -s com.microsoft.VSCodium c all
duti -s com.microsoft.VSCodium cfg all
duti -s com.microsoft.VSCodium class all
duti -s com.microsoft.VSCodium cpp all
duti -s com.microsoft.VSCodium cs all
duti -s com.microsoft.VSCodium css all
duti -s com.microsoft.VSCodium csv all
duti -s com.microsoft.VSCodium fish all
duti -s com.microsoft.VSCodium go all
duti -s com.microsoft.VSCodium h all
duti -s com.microsoft.VSCodium ini all
duti -s com.microsoft.VSCodium java all
duti -s com.microsoft.VSCodium jl all
duti -s com.microsoft.VSCodium js all
duti -s com.microsoft.VSCodium json all
duti -s com.microsoft.VSCodium log all
duti -s com.microsoft.VSCodium lua all
duti -s com.microsoft.VSCodium md all
duti -s com.microsoft.VSCodium ps1 all
duti -s com.microsoft.VSCodium py all
duti -s com.microsoft.VSCodium rb all
duti -s com.microsoft.VSCodium rs all
duti -s com.microsoft.VSCodium sh all
duti -s com.microsoft.VSCodium sql all
duti -s com.microsoft.VSCodium swift all
duti -s com.microsoft.VSCodium tf all
duti -s com.microsoft.VSCodium tmp all
duti -s com.microsoft.VSCodium toml all
duti -s com.microsoft.VSCodium ts all
duti -s com.microsoft.VSCodium tsv all
duti -s com.microsoft.VSCodium txt all
duti -s com.microsoft.VSCodium vue all
duti -s com.microsoft.VSCodium xlsx all
duti -s com.microsoft.VSCodium xml all
duti -s com.microsoft.VSCodium yaml all
duti -s org.videolan.vlc aac all
duti -s org.videolan.vlc alac all
duti -s org.videolan.vlc aiff all
duti -s org.videolan.vlc avi all
duti -s org.videolan.vlc flac all
duti -s org.videolan.vlc flv all
duti -s org.videolan.vlc m4a all
duti -s org.videolan.vlc m4v all
duti -s org.videolan.vlc mkv all
duti -s org.videolan.vlc mov all
duti -s org.videolan.vlc mp3 all
duti -s org.videolan.vlc mp4 all
duti -s org.videolan.vlc ogg all
duti -s org.videolan.vlc wav all
duti -s org.videolan.vlc webm all
duti -s org.videolan.vlc wma all
duti -s org.videolan.vlc wmv all

# Finder settings.

# Show hidden files in Finder.
defaults write com.apple.finder AppleShowAllFiles -bool true
# Use only the current folder for Finder searches.
defaults write com.apple.finder FXDefaultSearchScope SCcf
# Disable file extension change warning.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Show items in Finder via icon view.
defaults write com.apple.Finder FXPreferredViewStyle icnv
# Sort items in Finder by name.
defaults write com.apple.Finder FXPreferredGroupBy Name
# Show path bar in Finder folder window.
defaults write com.apple.finder ShowPathbar -bool true
# Hide recent tags from Finder sidebar.
defaults write com.apple.finder ShowRecentTags -bool false
# Do not show removable media on the desktop.
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
# Show status bar in Finder folder window.
defaults write com.apple.finder ShowStatusBar -bool true
# Show file extensions in Finder.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Do not autosave files to iCloud.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Keyboard settings.

# Switch to keyboard layout without alt character keys.
input_sources="$(
  defaults read com.apple.inputsources.plist AppleEnabledThirdPartyInputSources ||
    echo 'Missing Domain'
)"
if ! expr "${input_sources}" : '.*no_alt_characters.*' > /dev/null; then
  defaults write com.apple.inputsources.plist AppleEnabledThirdPartyInputSources -array-add '
    <dict>
      <key>InputSourceKind</key>
      <string>Keyboard Layout</string>
      <key>KeyboardLayout ID</key>
      <integer>5000</integer>
      <key>KeyboardLayout Name</key>
      <string>no_alt_characters</string>
    </dict>
  '
fi

# Change move workspace left keybinding to Ctrl+Option+J.
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 79 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>106</integer>
        <integer>38</integer>
        <integer>786432</integer>
      </array>
    </dict>
  </dict>
'
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 80 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>106</integer>
        <integer>38</integer>
        <integer>917504</integer>
      </array>
    </dict>
  </dict>
'
# Change move workspace right keybinding to Ctrl+Option+Semicolon.
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 81 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>59</integer>
        <integer>41</integer>
        <integer>786432</integer>
      </array>
    </dict>
  </dict>
'
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 82 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>59</integer>
        <integer>41</integer>
        <integer>917504</integer>
      </array>
    </dict>
  </dict>
'

# Privacy settings.

# Disable Apple intelligence report.
defaults write com.apple.AppleIntelligenceReport reportDuration -float 0
# Delete verification codes after use.
defaults write com.apple.onetimepasscodes DeleteVerificationCodes -bool true
# Disable Apple password manager.
defaults write com.apple.Safari AutoFillPasswords -bool false
# Disable sharing search queries with Apple.
defaults write com.apple.SpotlightResources.Defaults 'Search Queries Data Sharing Status' -float 2

# TextEdit settings.

# Save files to plain text by default.
defaults write com.apple.textedit RichText -bool false

# Activate keyboard shortcut changes.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
