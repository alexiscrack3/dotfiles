#!/bin/bash

echo "==> Setting up your dock..." 

dockutil --no-restart --remove all
dockutil --no-restart --add "/Applications/Android Studio.app"
dockutil --no-restart --add "/Applications/Google Chrome.app"
dockutil --no-restart --add "/Applications/iTerm.app"
dockutil --no-restart --add "/System/Applications/Music.app"
dockutil --no-restart --add "/Applications/Slack.app"
dockutil --no-restart --add "/Applications/Visual Studio Code.app"
dockutil --no-restart --add "/System/Applications/App Store.app"
dockutil --no-restart --add "/System/Applications/System Preferences.app"
dockutil --no-restart --add "~" --section others

killall Dock
