
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

###############################################################################
# Menu                                                                        #
###############################################################################

defaults write com.apple.menuextra.battery ShowPercent -string "YES"
defaults write com.apple.systemuiserver menuExtras -array "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" "/System/Library/CoreServices/Menu Extras/AirPort.menu" "/System/Library/CoreServices/Menu Extras/Battery.menu" "/System/Library/CoreServices/Menu Extras/Clock.menu"

###############################################################################
# Dock                                                                        #
###############################################################################

defaults write com.apple.dock show-recents -bool FALSE

###############################################################################
# Finder                                                                      #
###############################################################################

defaults write com.apple.LaunchServices/com.apple.launchservices.secure \
    LSHandlers -array-add \
    '{LSHandlerContentType=public.plain-text;LSHandlerPreferredVersions={LSHandlerRoleAll=-;};LSHandlerRoleAll = "com.microsoft.vscode";}'
