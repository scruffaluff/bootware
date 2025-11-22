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

defaults write org.musescore.MuseScore4 application.checkForUpdate -bool false
defaults write org.musescore.MuseScore4 application.hasCompletedFirstLaunchSetup -bool true
defaults write org.musescore.MuseScore4 application.paths.myPlugins -string "${HOME}/Music/MuseScore/Plugins"
defaults write org.musescore.MuseScore4 application.paths.myScores -string "${HOME}/Music/MuseScore/Scores"
defaults write org.musescore.MuseScore4 application.paths.mySoundfonts -string "${HOME}/Music/MuseScore/SoundFonts"
defaults write org.musescore.MuseScore4 application.paths.myStyles -string "${HOME}/Music/MuseScore/Styles"
defaults write org.musescore.MuseScore4 application.paths.myTemplates -string "${HOME}/Music/MuseScore/Templates"
defaults write org.musescore.MuseScore4 application.startup.modeStart -int 1
defaults write org.musescore.MuseScore4 project.alsoShareAudioCom -bool false
defaults write org.musescore.MuseScore4 project.autoSaveEnabled -bool false
