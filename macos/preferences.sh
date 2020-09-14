
###############################################################################
# Language & Region                                                           #
###############################################################################

defaults write NSGlobalDomain AppleLanguages -array "en-US" "en"

###############################################################################
# Keyboard                                                                    #
###############################################################################

defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>15000</integer><key>KeyboardLayout Name</key><string>USInternational-PC</string></dict>'
defaults write com.apple.HIToolbox AppleSelectedInputSources -array-add '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>15000</integer><key>KeyboardLayout Name</key><string>USInternational-PC</string></dict>'

###############################################################################
# Trackpad                                                                    #
###############################################################################

defaults write com.apple.universalaccess closeViewZoomDisplayID -bool true
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
