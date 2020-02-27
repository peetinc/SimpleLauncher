# SimpleLauncher
**2020.27.02 - Completely reworked and seems to work well now. MacOS Catalina made some "?documented?" changes to launchd that blocks the running of LaunchAgents and LaunchDaemons at startup. v1.2 is now an Xcode Objective-C wrapper around the same zsh script. I've included the STPrivilegedTask framwork in the hopes of working out a way to authenticate the app as root when double-clicked.
The main script has been moved to ./Resources/XcodeProject/Remote Acccess/Resources/script**

A simple app to allow SimpleHelp to simply run as root on macOS.

This project is the definition of As-Is.

Notes:
* Make sure your download preferences make it into /Library/Preferences/com.github.remoteaccess.plist (everything is a string, no bool!)
* Signed, but not notorized
* Edit variables in preinstall script for munkipkg (/App/munkipkg/Remote Access/scripts/preinstall)
* Use munkipkg to build deployable package after editing the preinstall script.
* Test it on a VM or two.
* Profit?

Cheers.Peet

![SimpleLauncher Logo](https://raw.githubusercontent.com/peetinc/SimpleLauncher/master/Code/Icons/icon.png)
