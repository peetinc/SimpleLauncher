#!/bin/zsh

launchctl unload /Library/LaunchDaemons/com.github.remoteaccess.install.plist
rm /Library/LaunchDaemons/com.github.remoteaccess.install.plist
launchctl unload /Library/LaunchAgents/com.github.remoteaccess.cleanup.plist
rm /Library/LaunchAgents/com.github.remoteaccess.cleanup.plist

rm -- "$0"

exit 0
