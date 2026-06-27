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
# Disable hot corners new note popup.
defaults write com.apple.doc wvous-br-corner -int 0
# Remove widgets from desktop.
defaults write com.apple.WindowManager StageManagerHideWidgets -bool true
defaults write com.apple.WindowManager StandardHideWidgets -bool true
# Speed up Mission Control animations.
defaults write com.apple.dock expose-animation-duration -float 0
defaults write com.apple.dock missioncontrol-animation-duration -float 0

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

for ext in bak bash c cfg class cpp css csv dockerignore env fish go h hpp \
  ini java jl js json jsx justfile log lua md nu ps1 py rb rs sh sql svelte \
  swift tf tmp toml ts tsv tsx txt vue xml yaml yml; do
  duti -s dev.zed.Zed "${ext}" all 2> /dev/null || true
done
for ext in doc docx ppt pptx xls xlsx; do
  duti -s org.libreoffice.script "${ext}" all 2> /dev/null || true
done
for ext in avif gif webp; do
  duti -s org.mozilla.firefox "${ext}" all 2> /dev/null || true
done
for ext in aac aiff avi flac flv m4a m4v mkv mov mp3 mp4 ogg wav webm wma wmv; do
  duti -s org.videolan.vlc "${ext}" all 2> /dev/null || true
done

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
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 33 '
<dict><key>enabled</key><false/></dict>
'
# Disable quick note `Fn+Q` key binding.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 190 '
<dict><key>enabled</key><false/></dict>
'
# Change Mission Control key binding to `Cmd+Ctrl+Up`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 32 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array>
        <integer>65535</integer>
        <integer>126</integer>
        <integer>9699328</integer>
      </array>
    </dict>
  </dict>
'
# Change focus workspace left key binding to `Cmd+Ctrl+J`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>106</integer>
      <integer>38</integer>
      <integer>1310720</integer>
    </array>
  </dict>
</dict>
'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 80 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>106</integer>
      <integer>38</integer>
      <integer>1441792</integer>
    </array>
  </dict>
</dict>
'
# Change focus workspace right key binding to `Cmd+Ctrl+Semicolon`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>59</integer>
      <integer>41</integer>
      <integer>1310720</integer>
    </array>
  </dict>
</dict>
'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 82 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>59</integer>
      <integer>41</integer>
      <integer>1441792</integer>
    </array>
  </dict>
</dict>
'
# Change focus workspace 1 key binding to `Cmd+Ctrl+1`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 118 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>18</integer>
      <integer>1310720</integer>
    </array>
  </dict>
</dict>
'
# Change focus workspace 2 key binding to `Cmd+Ctrl+2`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 119 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>19</integer>
      <integer>1310720</integer>
    </array>
  </dict>
</dict>
'
# Change focus workspace 3 key binding to `Cmd+Ctrl+3`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 120 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>20</integer>
      <integer>1310720</integer>
    </array>
  </dict>
</dict>
'
# Change focus workspace 4 key binding to `Cmd+Ctrl+4`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 121 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>21</integer>
      <integer>1310720</integer>
    </array>
  </dict>
</dict>
'
# Change focus workspace 5 key binding to `Cmd+Ctrl+5`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 122 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>22</integer>
      <integer>1310720</integer>
    </array>
  </dict>
</dict>
'
# Change focus workspace 6 key binding to `Cmd+Ctrl+6`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 123 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>23</integer>
      <integer>1310720</integer>
    </array>
  </dict>
</dict>
'
# Change focus workspace 7 key binding to `Cmd+Ctrl+7`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 124 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>24</integer>
      <integer>1310720</integer>
    </array>
  </dict>
</dict>
'
# Change focus workspace 8 key binding to `Cmd+Ctrl+8`.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 125 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>type</key><string>standard</string>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>25</integer>
      <integer>1310720</integer>
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
