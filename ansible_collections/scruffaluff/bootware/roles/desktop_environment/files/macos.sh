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

# Delete verification codes after use.
defaults write com.apple.onetimepasscodes DeleteVerificationCodes -bool true
# Prevent Stage Manager from hiding windows after a left click on desktop.
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
defaults write com.apple.WindowManager GloballyEnabled -bool false
# Disable alert beep sound.
defaults write 'Apple Global Domain' com.apple.sound.beep.volume -float 0
# Prevent accent character popup when holding down a key.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Disable window animations.
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
# Disable zoom animation for text input focus.
defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true
# Speed up window resize animations.
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
# Remove widgets from desktop.
defaults write com.apple.WindowManager StageManagerHideWidgets -bool true
defaults write com.apple.WindowManager StandardHideWidgets -bool true

# Dock and menu bar settings.

# Show menu bar background.
defaults write 'Apple Global Domain' SLSMenuBarUseBlurredAppearance -bool true
# Set dock to auto hide.
defaults write com.apple.dock autohide -bool true
# Set dock auto hide delay time to 0 seconds.
defaults write com.apple.dock autohide-delay -float 0
# Use simpler minimized animation for hiding applications.
defaults write com.apple.dock mineffect -string scale
# Minimize multiple windows of an applications to one dock icon.
defaults write com.apple.dock minimize-to-application -bool true
# Disable arranging spaces based on recent use for Amethyst.
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock workspaces-auto-swoosh -bool false
# Do not show recent applications in the dock.
defaults write com.apple.dock show-recents -bool false
# Remove keyboard settings from menu bar.
defaults write com.apple.TextInputMenu visible -bool false

# File extension settings.

duti -s dev.zed.Zed bak all
duti -s dev.zed.Zed bash all
duti -s dev.zed.Zed c all
duti -s dev.zed.Zed cfg all
duti -s dev.zed.Zed class all
duti -s dev.zed.Zed cpp all
duti -s dev.zed.Zed cs all
duti -s dev.zed.Zed css all
duti -s dev.zed.Zed csv all
duti -s dev.zed.Zed dockerignore all
duti -s dev.zed.Zed env all
duti -s dev.zed.Zed fish all
duti -s dev.zed.Zed go all
duti -s dev.zed.Zed h all
duti -s dev.zed.Zed hpp all
duti -s dev.zed.Zed ini all
duti -s dev.zed.Zed java all
duti -s dev.zed.Zed jl all
duti -s dev.zed.Zed js all
duti -s dev.zed.Zed json all
duti -s dev.zed.Zed jsx all
duti -s dev.zed.Zed justfile all
duti -s dev.zed.Zed log all
duti -s dev.zed.Zed lua all
duti -s dev.zed.Zed md all
duti -s dev.zed.Zed nu all
duti -s dev.zed.Zed ps1 all
duti -s dev.zed.Zed py all
duti -s dev.zed.Zed rb all
duti -s dev.zed.Zed rs all
duti -s dev.zed.Zed sh all
duti -s dev.zed.Zed sql all
duti -s dev.zed.Zed svelte all
duti -s dev.zed.Zed swift all
duti -s dev.zed.Zed tf all
duti -s dev.zed.Zed tmp all
duti -s dev.zed.Zed toml all
duti -s dev.zed.Zed ts all
duti -s dev.zed.Zed tsv all
duti -s dev.zed.Zed tsx all
duti -s dev.zed.Zed txt all
duti -s dev.zed.Zed vue all
duti -s dev.zed.Zed xml all
duti -s dev.zed.Zed yaml all
duti -s dev.zed.Zed yml all
duti -s org.libreoffice.script doc all
duti -s org.libreoffice.script docx all
duti -s org.libreoffice.script ppt all
duti -s org.libreoffice.script pptx all
duti -s org.libreoffice.script xls all
duti -s org.libreoffice.script xlsx all
duti -s org.mozilla.firefox avif all
duti -s org.mozilla.firefox gif all
duti -s org.mozilla.firefox webp all
duti -s org.videolan.vlc aac all
duti -s org.videolan.vlc aiff all
duti -s org.videolan.vlc alac all
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

# Do not write `.DS_Store` files on network drives.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# Show hidden files in Finder.
defaults write com.apple.finder AppleShowAllFiles -bool true
# Use only the current folder for Finder searches.
defaults write com.apple.finder FXDefaultSearchScope -string SCcf
# Disable file extension change warning.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Show items in Finder via icon view.
defaults write com.apple.finder FXPreferredViewStyle -string icnv
# Remove trash items older than 30 days.
defaults write com.apple.finder FXRemoveOldTrashItems -bool true
# Sort items in Finder by name.
defaults write com.apple.finder FXPreferredGroupBy Name
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

# Disable application windows `Ctrl+Down` key binding.
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 33 '
  <dict>
    <key>enabled</key><false/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>65535</integer>
        <integer>125</integer>
        <integer>865072</integer>
      </array>
    </dict>
  </dict>
'
# Change Mission Control key binding to `Ctrl+Option+Up`.
defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 32 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>65535</integer>
        <integer>126</integer>
        <integer>11272192</integer>
      </array>
    </dict>
  </dict>
'
# Change move workspace left key binding to `Ctrl+Option+J`.
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
# Change move workspace right key binding to `Ctrl+Option+Semicolon`.
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
# Disable extra bindings for function key.
defaults write com.apple.HIToolbox AppleFnUsageType -int 0
# Disable dictionary lookup on word track pad press.
defaults write 'Apple Global Domain' com.apple.trackpad.forceClick -int 0

# Privacy settings.

# Disable personalized advertisements.
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
# Disable Apple intelligence report.
defaults write com.apple.AppleIntelligenceReport reportDuration -float 0
# Disable Apple intelligence.
defaults write com.apple.CloudSubscriptionFeatures.optIn 545129924 -bool false
# Delete verification codes after use.
defaults write com.apple.onetimepasscodes DeleteVerificationCodes -bool true
# Disable sharing search queries with Apple.
defaults write com.apple.SpotlightResources.Defaults 'Search Queries Data Sharing Status' -float 2

# TextEdit settings.

# Save files to plain text by default.
defaults write com.apple.textedit RichText -bool false

# Activate keyboard shortcut changes.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
