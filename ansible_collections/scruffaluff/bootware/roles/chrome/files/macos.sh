#!/usr/bin/env sh
#
# Disable Google Chrome features for MacOS based on settings from
# https://github.com/corbindavenport/just-the-browser/blob/main/chrome/chrome.mobileconfig.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

defaults write com.google.Chrome AIModeSettings -int 1
defaults write com.google.Chrome CreateThemesSettings -int 2
defaults write com.google.Chrome DevToolsGenAiSettings -int 2
defaults write com.google.Chrome GeminiSettings -int 1
defaults write com.google.Chrome GenAILocalFoundationalModelSettings -int 1
defaults write com.google.Chrome HelpMeWriteSettings -int 2
defaults write com.google.Chrome HistorySearchSettings -int 2
defaults write com.google.Chrome TabCompareSettings -int 2
